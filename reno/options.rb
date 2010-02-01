module Reno
	class Option
		attr_reader :package, :parent, :name, :desc, :children
		
		def initialize(package, parent, name = nil, desc = nil, default = nil, block)
			@package = package
			@parent = parent
			@name = name
			@desc = desc
			@default = default
			@children = []
			@langs = {}
			instance_eval(&block) if block
		end
		
		def apply_config(conf, data)
			conf.langs << @langs
			@children.each do |child|
				child_data = data.elements.find { |element| element.attribute('name').value == child.name && element.name == child.xml_node } if data
				child.apply_config(conf, child_data)
			end
		end
		
		def xml_node
			"group"
		end
		
		def o(name, desc = nil, default = false, &block)
			@children << BooleanOption.new(@package, self, name, desc, default, block)
		end
		
		def group(name, desc = nil, &block)
			@children << Option.new(@package, self, name, desc, block)
		end
		
		def source(*args, &block)
			@children << SourceOption.new(@package, self, block, args)
		end
		
		alias :sources :source
		
		def default(hash)
			@package.default.merge!(hash)
		end
		
		def compiler(hash)
			# Verify that all languages exist
			hash.each_key { |key| Languages.locate(key) }
			
			@package.compilers.merge!(hash)
		end

		def lang(name = nil, &block)
			lang = Languages.locate(name, @package.default[:lang], @langs)
			obj = lang.new(self, block)
			@langs[lang] = obj
			obj
		end
	end
	
	class BooleanOption < Option
		def apply_config(conf, data)
			if (data && data.attribute('value')) ? data.attribute('value').value : @default
				super
			end
		end
		
		def xml_node
			"option"
		end
		
	end
	
	class SourceOption < Option
		def initialize(*args, sources)
			@sources = sources
			super *args
		end
		
		def apply_config(conf, data)
			conf.builder.sources.concat(@sources)
			conf = conf.derive(@sources)
			super
		end
		
		def xml_node
			"file"
		end
	end
end