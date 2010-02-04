module Reno
	module Toolchains
		class Gnu < Toolchain
			register :gnu, 'C'
			
			class << self	
				def command(file = nil)
					ENV['CC'] || 'gcc'
				end
				
				def compile(file)
					Builder.execute(command(file), *defines(file), '-c', file.path, '-o', file.output)
				end
				
				def defines(file)
					defines = []
					file.lang_conf.defines.each_pair do |key, value|
						defines << '-D' << (value ? "#{key}=#{value}" : key.to_s)
					end
					defines
				end
				
				def link(builder, output)
					Builder.execute(command(file), *builder.objects.map { |object| object.output }, '-o', output)
				end
			end
		end
	end
end