module Reno
	class Processor
		def self.use_component(package)
			package.state.set_processor(self, true)
		end
		
		def self.link(links)
			links.each_pair do |inputs, outputs|
				[*inputs].each do |input|
					[*outputs].each do |output|
						puts "linking #{self} : #{input} to #{output}"
						input.link Node::Link.new(self, output)
					end
				end
			end
		end
		
		def self.merger(*hash)
			hash.last.each_pair do |inputs, targets|
				inputs = Array === inputs ? inputs : [inputs]
				targets = Array === targets ? targets : [targets]
				targets.each do |target|
					link = Node::MergeLink.new(self, target)
					inputs.each do |input|
						input.link link
					end
				end
			end
		end
	end
end