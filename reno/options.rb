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
	
	class ListOption < Option
		def set(value)
			Array === value ? value : [value]
		end
		
		def merge(low, high)
			low + high
		end
		
		def default
			[]
		end
	end
	
	class BooleanOption < Option
		def present?(value)
			!(value == nil)
		end
	end
	
	class FileOption < Option
	end
	
	class OptionMap
		def initialize(map)
			@map = map
		end
		
		def [](option)
			@map.has_key?(option) ? @map[option] : option.default
		end
		
		def present?(option)
			@map.has_key?(option)
		end
		
		def each_pair(&block)
			@map.each_pair(&block)
		end
		
		def digest
			Digest.new
		end
	end
end
