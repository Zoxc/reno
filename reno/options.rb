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
		
		def update_digest(digest, value)
			digest.update value.to_s
		end
	end
	
	class HashOption < Option
		def merge(low, high)
			low.merge(high)
		end
		
		def default
			{}
		end
		
		def update_digest(digest, value)
			value.each_pair do |key, entry|
				digest.update key.to_s
				digest.update entry.to_s
			end
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
		
		def update_digest(digest, value)
			value.each { |entry| digest.update entry.to_s }
		end
	end
	
	class BooleanOption < Option
		def present?(value)
			!(value == nil)
		end
	end
	
	class FileOption < Option
		def update_digest(digest, value)
			digest.update Digest.from_file(value) if (value && ::File.exists(value))
		end
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
		
		def update_digest(digest)
			each_pair { |option, value| option.update_digest(digest, value) }
		end
	end
end
