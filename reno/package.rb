module Reno
	class PackageError < StandardError
	end
	
	Packages = {}

	class Package
		attr_reader :name, :version, :toolchain
		attr :desc, true
		attr :version, true

		def initialize(name, version = nil, &block)
			@name = name.to_s
			@version = version
			@options = block
			
			raise PackageError, "The package #{@name} already exist." if Packages[@name]
			Packages[@name] = self
	
			self
		end
		
		def load_config(data)
			conf = PackageConf.new(self)
			Options.new(conf, data, @options)
		end
	end
	
	class PackageConf
		def initialize(desc)
			@desc = desc
			@files = []
			@langs = {}
		end
		
		def file(name)
			@files.concat FileList[name]
		end
		
		def language(name)
			lang = @langs[name]
			unless lang
				raise PackageError, "Unable to find language #{name}." unless Languages.const_defined? name
				lang = Languages.const_get(name).new(self)
				@langs[name] = lang
			end
			lang
		end
	end

	class Library < Package
	end
	
	class Application < Package
	end
end