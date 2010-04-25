module Reno
	class Language
		def self.include_component(state)
			@lang_ext.each do |extension|
				extension.include_component(state)
			end
			
			language_state = @state_class.new
			language_state.include_component(state)
			
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