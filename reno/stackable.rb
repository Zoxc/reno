module Reno
	module Stackable
		def use_component(components, state)
			if components.has_component?(self.class, false)
				existing = components.get_component(self.class)
				existing << self
				self
			else
				components.set_component(self.class, [self])
				self
			end
		end
	end
end