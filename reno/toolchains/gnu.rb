require 'reno/languages/c'
require 'reno/languages/c++'

module Reno
	module Toolchains
		class Gnu < Toolchain
			register :gnu, 'C', 'C++'
			
			class << self	
				def command(*files)
					file = files.sort_by { |file| file.language.priority }.first
					
					case file.lang_conf
						when Languages::CXX
							ENV['CXX'] || 'g++'
						when Languages::C
							ENV['CC'] || 'gcc'
						else
							raise ToolchainError, "GCC doesn't support the language #{lang.language.name}."
					end
				end
				
				def language(file)
					case file.lang_conf
						when Languages::CXX
							'c++'
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
					file.lang_conf.get_defines(file).each_pair do |key, value|
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
						shared = if shared_library?(builder); '-shared' end
						dependencies = builder.dependencies.map do |dependency|
							if Symbol === dependency.output
								"-l#{dependency.output}"
							else
								dependency.output
							end
						end
						objects = builder.objects.map { |object| object.output }
						Builder.execute(command(*builder.objects), '-pipe', *shared, *objects, *dependencies, '-o', output)
					end
				end
			end
		end
	end
end