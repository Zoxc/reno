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
		
		def self.search(visited, stack, target, results)
			if self == target
				results << stack.dup
				return
			end
			
			return if visited.has_key?(self)
			visited[self] = true
			
			@links.each do |link|
				stack << link
				link.node.search(visited, stack, target, results)
				stack.pop
			end
		end
		
		def self.path(target)
			results = []
			search({}, [], target, results)
			result = results.min { |result| result.size }
		end
		
		attr_reader :state
		
		def initialize(components)
			@state = components.owner
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