module Reno
	class Node
		class Link
			attr_reader :processor
			
			def initialize(processor, node)
				@processor = processor
				@node = node
			end
			
			def process(path_result, node_instance)
				@processor.convert(node_instance, @node)
			end
			
			def search(state, path_result, target)
				@node.search(state, path_result, target)
			end
			
			def inspect
				"(#{@node} - #{@processor})"
			end
		end
		
		class MergeLink < Link
			def process(package, nodes)
				@processor.merge(package, nodes, @node)
			end
			
			def search(state, path_result, target)
				@node.search(path_result.state, path_result, target) if path_result.state
			end
		end
		
		class PathResult
			attr_reader :stack, :results, :state, :nodes
			
			def initialize(package)
				@stack = []
				@results = []
				@state = package ? package.state : nil
				@nodes = []
			end
			
			def inspect
				"#<#{self.class}:#{self.__id__} results=#{@results.size}>"
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
			
			def results
				@results
			end
			
			def result
				@result ||= @results.min { |result| result.size }
			end
			
			def self.follow(source_node, result_path)
				result_path.reduce(source_node) do |node, link|
					link.process(self, node)
				end
			end
			
			def follow(source_node, result_path = result)
				PathResult.follow(source_node, result_path)
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

		def self.link(link)
			@links << link
		end
		
		def self.search(state, path_result, target)
			if self == target
				path_result.save_stack
			end
			
			@links.each do |link|
				next if path_result.stack.include?(link)
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
	end
end