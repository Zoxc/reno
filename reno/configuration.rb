module Reno
	class ConfigurationNode
		attr_reader :langs, :builder, :parent
		
		def initialize(package, builder, parent, patterns)
			@package = package
			@builder = builder
			@parent = parent
			@patterns = patterns
			@children = []
			@langs = []
		end
		
		def derive(patterns)
			ConfigurationNode.new(@package, @builder, self, patterns)
		end
	end
end