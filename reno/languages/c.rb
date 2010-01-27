module Reno
	module Languages
		class C < Language
			attr_reader :defines
			
			def self.extensions
				['c']
			end
			
			def initialize(*args)
				@defines = {}
				super
			end
			
			def define(name, value = nil)
				@defines[name] = value
			end
		end
	end
end