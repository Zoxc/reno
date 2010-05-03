module Reno
	class Data
		attr_reader :state
		
		def initialize(node, state)
			@node = node
			@state = state
		end
		
		def use_component(components, state)
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