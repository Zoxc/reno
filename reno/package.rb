module Reno
	class PackageError < StandardError
	end
	
	Packages = {}
	
	class PackageOption < Option
		def name(name)
			@package.name = name
		end
		
		def desc(desc)
			@package.desc = desc
		end
		
		def version(version)
			@package.version = version
		end
		
		def compiler(hash)
			# Verify that all languages exist
			hash.each_key { |key| Languages.locate(key) }
			
			@package.compilers.merge!(hash)
		end
	end

	class Package
		attr_reader :default, :name, :compilers, :base, :output
		attr :desc, true
		attr :version, true

		def initialize(&block)
			@default = {}
			@compilers = {}
			@output = 'build'
			@base = Dir.getwd
			# This should be the last thing to be set up. The object might depend on the other variables.
			@option = PackageOption.new(self, nil, block)

			self
		end
		
		def name=(name)
			raise "You have already assigned this package a name" if @name
			
			@name = name.to_s

			raise PackageError, "The package #{@name} already exist." if Packages[@name]
			Packages[@name] = self
		end
		
		def builder(data)
			builder = Builder.new(self)
			conf = ConfigurationNode.new(@option.package, builder, nil, nil)
			builder.conf = conf
			@option.apply_config(conf, data)
			builder
		end

		def load_config(data)
			conf = PackageConf.new(self)
			Options.new(conf, data, @options)
		end
	end

	class Library < Package
	end
	
	class Application < Package
	end
end