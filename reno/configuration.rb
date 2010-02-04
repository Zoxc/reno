module Reno
	class ConfigurationError < StandardError
	end
	
	class ConfigurationNode
		attr_reader :langs, :builder, :parent, :hash, :patterns
		
		def initialize(package, builder, parent, patterns)
			@package = package
			@builder = builder
			@parent = parent
			@patterns = patterns.to_a
			@children = []
			@hash = {}
		end
		
		def add(name, values)
			@hash[name] = [] unless @hash.has_key?(name)
			@hash[name].concat(values)
		end
		
		def get(name, file = nil, base = nil)
			if file && !@patterns.empty?
				Dir.chdir(base) do
					return nil unless @patterns.any? { |pattern| File.fnmatch?(pattern, file) }
				end
			end
			
			child_values = []
			
			@children.each do |child|
				child_values.concat(child.get(name, file).reject { |value| !value })
			end
			
			if Array === @hash[name]
				@hash[name] + child_values
			else
				child_values
			end
		end
		
		def derive(patterns)
			patterns = patterns.to_a
			child = ConfigurationNode.new(@package, @builder, self, patterns)
			child.add(:patterns, patterns)
			@children << child
			child
		end
	end
end