module Reno
	module Languages
		class C < Language
			class State
				include Mergable
				
				def merge(other)
				end
			end
			
			class Interface
				def initialize(state)
				end
				
				def std(std)
				end
				
				def define(name, value = nil)
				end
			end
			
			class File < Reno::File
			end
			
			register :state, State
			register :interface, Interface
			register :ext, 'c', File
		end
	end
end