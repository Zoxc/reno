module Reno
	class Node
		class Link
			attr_reader :processor
			attr_reader :node
			
			def initialize(processor, node)
				@processor = processor
				@node = node
			end
			
			def process(node_instance)
				node = @processor.convert(node_instance, @node)
				raise "Link #{@processor} => #{@node} resulted in #{node.class}" if node.class != @node
				node
			end
			
			def search(state, path_result, target)
				@node.search(state, path_result, target)
			end
		end
		
		class PathResult
			attr_reader :visited, :stack, :results, :state
			
			def initialize(package)
				@visited = {}
				@stack = []
				@results = []
				@state = package ? package.state : nil
			end
			
			def visited?(node)
				@visited.has_key?(node)
			end
			
			def push(link)
				@stack << link
			end
			
			def pop
				@stack.pop
			end
			
			def save_stack
				@results << @stack.dup
			end
			
			def empty?
				@results.empty?
			end
			
			def visit(node)
				@visited[node] = true
			end
			
			def results
				@results
			end
			
			def result
				@result ||= @results.min { |result| result.size }
			end
			
			def follow(source_node, result_path = result)
				result_path.reduce(source_node) do |node, link|
					link.process(node)
				end
			end
		end
		
		def self.node_name
			name.downcase.gsub('::', '.')
		end
		
		def self.setup_subclass
			@links = []
			@mergers = []
		end
		
		def self.inherited(subclass)
			subclass.setup_subclass
		end
		
		def self.links
			@links
		end

		def self.mergers
			@mergers
		end
		
		def self.link(processor, node)
			@links << Link.new(processor, node)
		end
		
		def self.merger(processor)
			@mergers << processor
		end
		
		def self.search(state, path_result, target)
			if self == target
				path_result.save_stack
				return
			end
			
			return if path_result.visited?(self)
			path_result.visit self
			
			@links.each do |link|
				next unless state.get_processor(link.processor)
				path_result.push link
				link.search(state, path_result, target)
				path_result.pop
			end
		end
		
		def self.path(package, state, target)
			path_result = PathResult.new(package)
			results = []
			search(state, path_result, target)
			path_result
		end
		
		attr_reader :state
		
		def initialize(state)
			@state = state
		end
		
		def cache(target, option_set = nil, &block)
			@state.package.cache.cache(self, target, option_set, &block)
		end
		
		def path(target, package = nil)
			result = self.class.path(package, @state, target)
			result.empty? ? nil : result
		end
		
		def use_component(components)
			if components.has_component?(Node, false)
				existing = components.get_component(self.class)
				existing << self
				self
			else
				components.set_component(Node, [self])
				self
			end
		end
	end
end