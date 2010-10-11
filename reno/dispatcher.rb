module Reno
	class Task
		attr_reader :children, :edges, :work
		attr :completed, true
		
		def initialize(&work)
			@work = work
			@queued = false
			@children = []
			@edges = []
		end
		
		def queued
			@queued = true
		end
		
		def requires(tasks)
			@children.concat(tasks)
		end
		
		def complete(dispatcher)
			@completed = true
			@edges.each do |edge|
				edge.children.delete self
				dispatcher.add_leaf(edge) if edge.children == []
			end
		end
		
		def queued?
			@queued
		end
	end
	
	class Dispatcher
		class Thread
			def initialize(dispatcher)
				@dispatcher = dispatcher
				@thread = ::Thread.new do
					loop do
						task = @dispatcher.schedule
						task.work.call
						@dispatcher.complete(task)
					end
				end
			end
		end
		
		def initialize(thread_count)
			@threads = (1..thread_count).map { Thread.new(self) }
			@leafs = []
			@sleeping = []
			@leaf_access = Mutex.new
			@task_access = Mutex.new
		end
		
		def complete(task)
			@task_access.synchronize do
				task.complete self
				wake_thread(@waiting_thread) if @waiting_task == task
			end
		end
		
		def schedule
			@leaf_access.synchronize do
				loop do
					task = @leafs.shift
					return task if task
					
					@sleeping.push ::Thread.current
					@leaf_access.sleep
				end
			end
		end
		
		def wake_thread(thread)
			thread.wakeup if thread
		rescue ThreadError
			retry
		end
		
		def add_leaf(task)
			@leaf_access.synchronize do
				@leafs << task
				wake_thread(@sleeping.shift)
			end
		end
		
		def wait(task)
			@task_access.synchronize do
				return if task.completed
				@waiting_thread = ::Thread.current
				@waiting_task = task
				@task_access.sleep
			end
		end
		
		def queue(task)
			return if task.queued?
			task.queued
			
			task.children.each do |child|
				child.edges << task
				queue(child)
			end
			
			add_leaf(task) if task.children == []
		end
	end
end