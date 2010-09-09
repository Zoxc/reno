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
			@targets ||= []
			@targets.concat targets
			targets.each do |target|
				target.merger(self)
			end
		end
		
		def self.merges?(target)
			@targets.include?(target)
		end
		
		def self.eval_merge_simple(nodes, target, merge_target)
			return nil unless merges?(merge_target)
			eval_nodes(nodes, [target])
		end
		
		class MergeAction
			include Comparable

			attr_reader :merger, :paths
			
			def initialize(merger, paths)
				@merger = merger
				@paths = paths
			end
			
			def <=>(other)
				steps <=> other.steps
			end
			
			def steps
				@steps ||= paths.reduce { |sum, path| sum + path.size }
			end
		end
		
		def self.eval_nodes(nodes, allowed)
			paths = nodes.map do |node|
				path = allowed.map do |target|
					node.class.path(target)
				end.find_all.min { |path| path.size }
				return nil unless path
				path
			end
			MergeAction.new(self, paths)
		end
	end
end