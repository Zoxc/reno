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
	end

	class Package
		attr_reader :default, :name, :base, :output
		attr :desc, true
		attr :version, true

		def initialize(&block)
			@default = {}
			@output = 'build'
			@base = Dir.getwd
			# This should be the last thing to be set up. The object might depend on the other variables.
			@option = PackageOption.new(self, nil, block)

			self
		end
		
		def output_name
			raise "You can't link packages!"
		end
		
		def name=(name)
			raise "You have already assigned this package a name" if @name
			
			@name = name.to_s

			raise PackageError, "The package #{@name} already exist." if Packages[@name]
			Packages[@name] = self
		end
		
		def builder(data = nil)
			builder = Builder.new(self)
			conf = ConfigurationNode.new(@option.package, builder, nil, [])
			@option.apply_config(conf, data)
			builder.conf = conf
			builder
		end

		def load_config(data)
			conf = PackageConf.new(self)
			Options.new(conf, data, @options)
		end
	end

	class Library < Package
		def output_name
			if Rake::Win32.windows?
				@name + '.dll'
			else
				@name + '.so'
			end
		end
	end
	
	class Application < Package
		def output_name
			if Rake::Win32.windows?
				@name + '.exe'
			else
				@name
			end
		end
	end
end