module Reno
	module Languages
		class Language
			attr_reader :option
			
			def initialize(option)
				@option = option
			end
		end
	end
end