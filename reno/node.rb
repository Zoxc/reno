module Reno
	class Node
		class Link
			attr_reader :processor
			attr_reader :node
			
			def initialize(processor, node)
				@processor = processor
				@node = processor
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
		
		def self.link(processor, output)
			@links << Link.new(processor, output)
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
			return if state
			
			@links.each do |link|
				stack << link
				link.output.search(visited, stack, target, results)
				stack.pop
			end
		end
		
		def self.path(state, target)
			results = []
			search(state, {}, [], target, results)
			result = results.min { |result| result.size }
		end
		
		attr_reader :state
		
		def initialize(components)
			@state = components.owner
		end
		
		def use_component(components)
			if components.has_component?(Data, false)
				existing = components.get_component(Data)
				existing << self
				self
			else
				components.set_component(Data, [self])
				self
			end
		end
	end
end