module Reno
	module Mergable
		def use_component(components, state)
			if components.has_component?(self.class, false)
				existing = components.get_component(self.class)
				existing.merge(self)
				existing
			else
				components.set_component(self.class, self)
				self
			end
		end
	end
end