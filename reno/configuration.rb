module Reno
	class ConfigurationNode
		attr_reader :langs, :conf, :parent
		
		def initialize(package, conf, parent, patterns)
			@package = package
			@conf = conf
			@parent = parent
			@patterns = patterns
			@children = []
			@langs = []
		end
		
		def derive(patterns)
			ConfigurationNode.new(@package, @conf, self, patterns)
		end
	end
end