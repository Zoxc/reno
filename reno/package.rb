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
	
	class Dependency
		def locate(path)
			package = Packages[@name]
			
			unless package
				dir = File.expand_path(path, @parent.base)
				file = File.join(dir, "#{@name}.renofile")
				
				if File.exists? file
					begin
						old_path = Thread.current[:"Reno::Package.wd"]
						Thread.current[:"Reno::Package.wd"] = dir
						
						unless $LOAD_PATH.any? { |lp| File.expand_path(lp) == dir }
							$LOAD_PATH.unshift(dir)
						end
						
						load file
					ensure
						Thread.current[:"Reno::Package.wd"] = old_path
					end
				end
			end
			
			return Packages[@name]
		end
		
		def initialize(parent, name, options)
			@parent = parent
			@name = name.to_s
			@library = options[:library]
			
			# Locate the package
			paths = ['.', File.join('.', @name)]
			paths.unshift(options[:path]) if options[:path]
			paths.find { |path| @package = locate(path) }
			
			raise PackageError, "Unable to find dependency '#{@name}' for package '#{@parent.name}'." unless @package
		end
		
		def build
			@package.build_package(nil, @library)
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
		
		def option_factory(block)
			PackageOption.new(self, nil, block)
		end

		def initialize(&block)
			@default = {}
			@output = 'build'
			@base = Thread.current[:"Reno::Package.wd"]
			@dependencies = []
			@mutex = Mutex.new
			@type = :application
			
			# This should be the last thing to be set up. The object might depend on the other variables.
			@option = option_factory(block)

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
		
		def create_conf
			conf = ConfigurationNode.new(@option.package, nil, [])
			
			@option.apply_config(conf, data)
			
			conf
		end
		
		def build_package(data, library)
			dependencies = @dependencies.map { |dependency|	dependency.build }
			
			@mutex.lock
			
			conf = create_conf
			
			builder = Builder.new(self, library, dependencies, conf)
			builder.run
			
			output = builder.output_name
			
			dependencies.each do |dependency|
				mutex = dependency.mutex
				mutex.unlock if mutex
			end
			
			PackageResult.new(self, conf, @mutex, output)
		end
		
		def build(data = nil, library = nil)
			mutex = build_package(data, library).mutex
			mutex.unlock if mutex
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
	
	class CompiledLibraryOption < PackageOption
		def library(library, shared = false)
			@package.library = {:library => library, :shared => shared}
		end
	end
	
	class CompiledLibrary < Library
		attr :library, true
		
		def option_factory(block)
			CompiledLibraryOption.new(self, nil, block)
		end
		
		def build_package(data, library)
			PackageResult.new(self, create_conf, nil, @library)
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