module Reno
	module Arch
		class X86
			Enable3DNow = BooleanOption.new
			MMX = BooleanOption.new
			SSE = BooleanOption.new
			SSE2 = BooleanOption.new
			
			def self.name
				'x86'
			end
		end
	end
end
