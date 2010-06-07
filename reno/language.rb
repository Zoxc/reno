module Reno
	class Language
		class DeferedState
			def initialize(components, state_class)
				state = components.owner
				@package = state.package
				@private = components == state.private
				@state_class = state_class
			end
			
			def get_components
				@private ? @package.state.private : @package.state.public
			end
			
			def get
				components = get_components
				
				if components.has_component?(@state_class, false)
					components.get_component(@state_class)
				else
					state = @state_class.new
					components.use(state)
					state
				end
			end
		end
		
		def self.use_component(components)
			@lang_ext.each do |extension|
				components.use(extension)
			end
			
			@interface_class.new(DeferedState.new(components, @state_class))
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