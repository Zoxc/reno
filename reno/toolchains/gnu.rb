module Reno
	module Toolchains
		class Gnu < Toolchain
			register :gnu, 'C'
			
			class << self	
				def command(file = nil)
					ENV['CC'] || 'gcc'
				end
				
				def language(file)
					case file.lang_conf
						when Languages::C
							'c'
						else
							raise ToolchainError, "GCC doesn't support the language #{file.language.name}."
					end
				end
				
				def compile(file)
					headers = file.language.extract_headers(file.language, file.builder.dependencies)
					shared = if shared_library?(file.builder); '-fPIC' end
					Builder.execute(command(file), '-pipe', *shared, *defines(file), *std(file), '-x', language(file), *headers.map { |header| ['-I', header]}.flatten, '-c', file.path, '-o', file.output)
				end
				
				def std(file)
					case file.lang_conf.read(:std)
						when nil
							return []
						when :c89
							result = '89'
						when :c99
							result = '99'
						else
							raise ToolchainError, "Unable to find language mode #{file.lang_conf.read(:std)}."
					end
					
					["-std=#{file.lang_conf.read(:strict) ? "c" : "gnu"}#{result}"]
				end
				
				def defines(file)
					defines = []
					file.lang_conf.read(:defines).each_pair do |key, value|
						defines << '-D' << (value ? "#{key}=#{value}" : key.to_s)
					end
					defines
				end
				
				def shared_library?(builder)
					builder.package.type == :library && builder.library != :static
				end
				
				def link(builder, output)
					if builder.package.type == :library && !shared_library?(builder)
						Builder.execute('ar', 'rsc', output, *builder.objects.map { |object| object.output })
					else
						Builder.execute(command, '-pipe', *if shared_library?(builder); '-shared' end, *builder.dependencies.map { |dependency| dependency.output }, *builder.objects.map { |object| object.output }, '-o', output)
					end
				end
			end
		end
	end
end