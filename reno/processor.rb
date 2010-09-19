module Reno
	class Processor
		def self.use_component(package)
			package.state.set_processor(self, true)
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
		
		def self.eval_merge_simple(collection, target, merge_target)
			return nil unless merges?(merge_target)
			eval_nodes(collection, [target], merge_target)
		end
		
		class MergeAction
			include Comparable

			attr_reader :merger, :paths
			
			def initialize(merger, package, paths, target)
				@merger = merger
				@package = package
				@paths = paths
				@target = target
			end
			
			def <=>(other)
				steps <=> other.steps
			end
			
			def steps
				@steps ||= @paths.reduce { |sum, path| sum + path.steps }
			end
			
			def run
				collection = Collection.new(@package)
				collection.nodes.concat(@paths.map { |path| path.follow })
				@merger.merge(collection, @target)
			end
		end
		
		def self.eval_nodes(collection, allowed, merge_target)
			paths = collection.nodes.map do |node|
				path = allowed.map do |target|
					node.path(target)
				end.find_all.min { |path| path.steps }
				return nil unless path
				path
			end
			MergeAction.new(self, collection.package, paths, merge_target)
		end
	end
end