module Reno
	class Language
		def self.use_component(package)
			package.state.set_option File::Extension, @lang_ext
			@interface_class.new(package)
		end
		
		def self.register(type, *args)
			case type
				when :ext
					ext, file = *args
					@lang_ext[ext] = file
					file.register :ext, ext
				when :interface
					@interface_class = args.first
			end
		end
		
		def self.inherited(language)
			language.instance_variable_set(:@lang_ext, {})
		end
	end
end