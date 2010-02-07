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
	
	class PackageResult
		attr_reader :package, :conf, :mutex, :output
		
		def initialize(package, conf, mutex, output)
			@package = package
			@conf = conf
			@mutex = mutex
			@output = output
		end
	end

	class Package
		attr_reader :default, :name, :base, :output, :type
		attr :desc, true
		attr :version, true

		def initialize(&block)
			@default = {}
			@output = 'build'
			@base = Thread.current[:"Reno::Package.wd"]
			@dependencies = []
			@mutex = Mutex.new
			@type = :application
			
			# This should be the last thing to be set up. The object might depend on the other variables.
			@option = PackageOption.new(self, nil, block)

			self
		end
		
		def output_name(builder)
			raise "You can't link packages!"
		end
		
		def name=(name)
			raise "You have already assigned this package a name" if @name
			
			@name = name.to_s

			raise PackageError, "The package #{@name} already exist." if Packages[@name]
			Packages[@name] = self
		end
		
		def dependency(dependency)
			@dependencies << dependency
		end
		
		def build_package(data, library)
			dependencies = @dependencies.map { |dependency|	dependency.build_package(nil, nil) }
			
			@mutex.lock
			
			builder = Builder.new(self, library, dependencies)
			conf = ConfigurationNode.new(@option.package, builder, nil, [])
			@option.apply_config(conf, data)
			builder.conf = conf
			builder.run
			
			output = builder.output_name
			
			dependencies.each { |dependency| dependency.mutex.unlock }
			
			PackageResult.new(self, conf, @mutex, output)
		end
		
		def build(data = nil, library = nil)
			build_package(data, library).mutex.unlock
		end
	end
	
	Thread.current[:"Reno::Package.wd"] = Dir.getwd

	class Library < Package
		def initialize(*args)
			result = super
			@type = :library
			result
		end
		
		def output_name(builder)
			if Platforms.current == Platforms::Windows
				@name + (builder.library == :static ? '.lib' : '.dll')
			else
				@name + (builder.library == :static ? '.a' : '.so')
			end
		end
	end
	
	class CompiledLibrary < Library
		def builder(data, library)
			
		end
	end
	
	class Application < Package
		def output_name(builder)
			if Platforms.current == Platforms::Windows
				@name + '.exe'
			else
				@name
			end
		end
	end
end