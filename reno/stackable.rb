module Reno
	module Stackable
		def use_component(state, settings)
			if state.has_component?(self.class, false)
				existing = state.get_component(self.class)
				existing << self
				self
			else
				state.set_component(self.class, [self])
				self
			end
		end
	end
end