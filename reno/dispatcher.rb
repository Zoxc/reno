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
			@children_left =  @children.size
		end

		def try_add(dispatcher)
			dispatcher.add_leaf(self) if @children_left == 0
		end
		
		def child_complete(dispatcher)
			@children_left -= 1
			try_add(dispatcher)
		end
		
		def requires(*tasks)
			@children.concat(tasks)
		end
		
		def result
			@result
		end
		
		def complete(dispatcher, result)
			@completed = true
			@result = result
			@edges.each do |edge|
				edge.child_complete dispatcher
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
						@dispatcher.complete(task, task.work.call(task))
					end
				end
			end
		end
		
		def default_thread_count
			4
		end
		
		def initialize(thread_count = default_thread_count)
			@threads = (1..thread_count).map { Thread.new(self) }
			@leafs = []
			@sleeping = []
			@leaf_access = Mutex.new
			@task_access = Mutex.new
		end
		
		def complete(task, result)
			@task_access.synchronize do
				task.complete self, result
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
				return task.result if task.completed
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
			
			@task_access.synchronize do
				task.try_add(self)
			end
		end
		
		def run(task)
			queue(task)
			wait(task)
		end
	end
end