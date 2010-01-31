module Reno
	module Compilers
		class Gcc < Compiler
			register 'C'
			
			class << self	
				def command
					ENV['CC'] || 'gcc'
				end
					
				def  compile(file)
					Builder.execute(command, '-c', file.path, '-o', file.output)
				end
			end
		end
	end
end