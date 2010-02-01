module Reno
	module Toolchains
		class Gnu < Toolchain
			register :gnu, 'C'
			
			class << self	
				def command(file = nil)
					ENV['CC'] || 'gcc'
				end
				
				def compile(file)
					Builder.execute(command(file), '-c', file.path, '-o', file.output)
				end
				
				def link(builder, output)
					Builder.execute(command(file), *builder.objects.map { |object| object.output }, '-o', output)
				end
			end
		end
	end
end