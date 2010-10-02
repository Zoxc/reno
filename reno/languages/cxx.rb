module Reno
	module Languages
		class CXX < Language
			Standard = Option.new
			
			class Interface < C::Interface
				def std(std)
					state.set_option Standard, std
				end
			end
			
			class File < Reno::File
				register :dependency_generator, C::Preprocessor
			end
			
			class HeaderFile < Reno::File
				register :dependency_generator, C::Preprocessor
				collect false
			end
			
			register :interface, Interface
			register :ext, 'cpp', File
			register :ext, 'cxx', File
			register :ext, 'hpp', HeaderFile
			register :ext, 'hxx', HeaderFile
		end
	end
end