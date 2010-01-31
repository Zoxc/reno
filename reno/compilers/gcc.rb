module Reno
	module Compilers
		class Gcc < Compiler
			register 'C'
			
			def self.compile(file)
				puts "Compiling #{file.name} as #{file.language}..."
			end
		end
	end
end