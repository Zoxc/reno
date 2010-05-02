module Reno
	class Language
		def self.use_component(state, settings)
			@lang_ext.each do |extension|
				state.use(extension, settings)
			end
			
			language_state = @state_class.new
			state.use(language_state, settings)
			
			@interface_class.new(language_state)
		end
		
		def self.register(type, *args)
			case type
				when :ext
					ext, file = *args
					@lang_ext.push(File::Extension.new(ext, file))
				when :state
					@state_class = args.first
				when :interface
					@interface_class = args.first
			end
		end
		
		def self.inherited(language)
			language.instance_variable_set(:@lang_ext, [])
		end
	end
end