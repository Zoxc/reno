module Reno
	class Node
		class Link
			attr_reader :processor
			attr_reader :node
			
			def initialize(processor, node)
				@processor = processor
				@node = node
			end
		end
		
		class Path
			def initialize(node, path)
				@node = node
				@path = path
			end
			
			def steps
				@path.size
			end
			
			def follow
				node = @node
				@path.each do |link|
					node = link.processor.convert(node, link.node)
					raise "Link #{link.processor} => #{link.node} resulted in #{node.class}" if node.class != link.node
				end
				node
			end
		end
		
		def self.node_name
			name.downcase.sub('::', '.')
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
		
		def self.search(state, visited, stack, target, results)
			if self == target
				results << stack.dup
				return
			end
			
			return if visited.has_key?(self)
			visited[self] = true
			
			@links.each do |link|
				next unless state.get_processor(link.processor)
				stack << link
				link.node.search(state, visited, stack, target, results)
				stack.pop
			end
		end
		
		def self.path(state, target)
			results = []
			search(state, {}, [], target, results)
			result = results.min { |result| result.size }
		end
		
		attr_reader :state
		
		def initialize(state)
			@state = state
		end
		
		def cache(target, &block)
			@state.package.cache.cache(self, target, &block)
		end
		
		def path(target)
			result = self.class.path(@state, target)
			result ? Path.new(self, result) : nil
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