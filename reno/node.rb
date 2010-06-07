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
		
		def self.inherited(subclass)
			@links = []
		end
		
		def self.link(processor, output)
			@links << Link.new(processor, output)	
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