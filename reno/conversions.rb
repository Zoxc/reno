module Reno
	module Conversions
		class ConversionError < StandardError
		end
		
		@map = {}
		
		def self.register(from, &block)
			@map[from] = block
		end
		
		def self.convert(from, components)
			result = @map[from.class]
			return result.call(from, components) if result
			
			@map.each_key do |key|
				return @map[key].call(from, components) if key < from.class
			end
			
			raise ConversionError, "Unable to find conversion for type '#{from.class.inspect}'"
		end
	end
end