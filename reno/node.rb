module Reno
	class Node
		attr_reader :state
		
		def initialize(state)
			@state = state
		end
		
		def use_component(state, settings)
			if state.has_component?(Node, false)
				existing = state.get_component(Node)
				existing << self
				self
			else
				state.set_component(Node, [self])
				self
			end
		end
	end
end