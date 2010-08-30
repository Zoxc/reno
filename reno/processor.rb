module Reno
	class Processor
		def self.use_component(components)
			components.set_component(self, self) unless components.has_component?(self, false)
		end
		
		def self.link(links)
			links.each_pair do |input, output|
				input.link(self, output)
			end
		end
		
		def self.merger(*targets)
			targets.each do |target|
				target.merger(self)
			end
		end
		
		def self.eval_nodes(nodes, allowed)
			links.each_pair do |input, output|
				input.link(self, output)
			end
		end
	end
end