module Reno
	module Mergable
		def use_component(state, settings)
			if state.has_component?(self.class, false)
				existing = state.get_component(self.class)
				existing.merge(self)
				existing
			else
				state.set_component(self.class, self)
				self
			end
		end
	end
end