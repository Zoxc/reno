module Reno
	module Languages
		class C < Language
			Standard = Option.new
			Defines = HashOption.new
			
			class Interface < Reno::Interface
				def std(std)
					state.set_option Standard, std
				end
				
				def define(name, value = nil)
					state.set_option Defines, {name => value}
				end
			end
			
			class File < Reno::File
			end
			
			register :interface, Interface
			register :ext, 'c', File
		end
	end
end