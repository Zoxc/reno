module Reno
	class Data
		attr_reader :settings
		
		def initialize(node, settings)
			@node = node
			@settings = settings
		end
		
		def use_component(state, settings)
			if state.has_component?(Data, false)
				existing = state.get_component(Data)
				existing << self
				self
			else
				state.set_component(Data, [self])
				self
			end
		end
	end
end