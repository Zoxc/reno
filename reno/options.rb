module Reno	
	class Option
		def new(value)
			value
		end
		
		def merge(low, high)
			high
		end
		
		def default
			nil
		end
	end
	
	class HashOption < Option
		def merge(low, high)
			low.merge(high)
		end
		
		def default
			{}
		end
	end
end
