require 'reno/languages/c'

module Reno
	module Languages
		class CXX < C
			self.name = 'C++'
			
			def self.extensions
				['.cpp', '.hpp']
			end

			def priority
				1
			end
			
			def calc_defines(file, language = C)
				super(file, C).merge(super(file, CXX))
			end
			
			def self.extract_headers(language, dependencies)
				super(C, dependencies) + super(language, dependencies)
			end
		end
	end
end