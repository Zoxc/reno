module Reno	
	class Option
		def set(value)
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
	
	class OptionMap
		def initialize(map)
			@map = map
		end
		
		def [](option)
			@map[option]
		end
		
		def digest
			Digest.new
		end
	end
end
