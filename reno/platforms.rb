module Reno
	module Platforms
		class Windows
		end
		
		class Unix
		end
		
		def self.current
			if RUBY_PLATFORM =~ /(win|w)32$/
				Windows
			else
				Unix
			end
		end
	end
end
