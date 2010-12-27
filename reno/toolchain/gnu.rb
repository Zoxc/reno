module Reno
	module Toolchain
		module GNU
			AS = 'as'
			AR = 'ar'
			GCC = ENV['CC'] || 'gcc'
			GXX = ENV['CXX'] || 'g++'
			LD = ENV['LD'] || 'ld'
			
			Prefix = Option.new
			LinkTimeOptimization = BooleanOption.new
			
			class Assembler < Processor
				link Assembly => ObjectFile
				
				def self.convert(node, target)
					node.cache(target, [Prefix, Architecture]) do |output, option_map|
						options = []
						
						option_map.each_pair do |option, value|
							case option
								when Architecture
									if value == Arch::X86
										options << '--32'
									elsif value == Arch::X86_64
										options << '--64'
									end
							end
						end
						
						Builder.execute "#{option_map[Prefix]}#{AS}", *options, node.filename, '-o', output
					end
				end
			end
			
			class Compiler < Processor
				link [Languages::C::File, Languages::CXX::File] => [ObjectFile, Assembly]
				
				Options = [
					Prefix,
					LinkTimeOptimization,
					Architecture,
					Optimization,
					MergeConstants,
					Exceptions,
					Reflection,
					StackProtection,
					DebugInformation,
					Arch::X86::Enable3DNow,
					Arch::X86::MMX,
					Arch::X86::SSE,
					Arch::X86::SSE2,
					Arch::X86_64::MemoryModel,
					Arch::FreeStanding,
					Arch::RedZone,
					Languages::C::Standard,
					Languages::C::Includes,
					Languages::C::Defines,
					Languages::CXX::Standard
				]
				
				def self.convert(node, target)
					node.cache(target, Options) do |output, option_map|
						stop = if target == ObjectFile
							'-c'
						elsif target == Assembly
							'-S'
						else
							raise "Unknown target #{target}"
						end
						
						lang = case node
							when Languages::C::File
								['c', Languages::C::Standard, GCC]
								
							when Languages::CXX::File
								['c++', Languages::CXX::Standard, GXX]
							else
								raise "Unknown language #{node.class.node_name}"
						end
						
						options = []
						
						options << "-std=gnu#{option_map[lang[1]][1..-1]}" if option_map.present? lang[1]
						
						option_map.each_pair do |option, value|
							case option
								when Architecture
									if value == Arch::X86
										options << '-m32'
									elsif value == Arch::X86_64
										options << '-m64'
									end
								
								when LinkTimeOptimization
									options << '-flto' if value
								
								when Optimization
									options.concat(case value
										when :none
											[]
										when :speed
											['-O3']
										when :balanced
											['-O2']
										when :size
											['-Os']
									end)
								
								when MergeConstants
									options << "-f#{"no-" unless value}merge-constants"
								
								when Exceptions
									options << "-f#{"no-" if value == :none}exceptions"
									
								when Reflection
									options << "-f#{"no-" unless value}rtti" && lang.first == 'c++'
									
								when StackProtection
									options.concat(case value
										when :none
											['-fno-stack-protector']
										when :partial
											['-fstack-protector']
										when :full
											['-fstack-protector-all']
									end)
									
								when DebugInformation
									options << "-g"
								
								when Arch::X86::Enable3DNow
									options << "-m#{"no-" unless value}3dnow" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86::MMX
									options << "-m#{"no-" unless value}mmx" if option_map[Architecture] <= Arch::X86
									
								when Arch::X86::SSE
									options << "-m#{"no-" unless value}sse" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86::SSE2
									options << "-m#{"no-" unless value}sse2" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86_64::MemoryModel
									options << "-mcmodel=#{value}" if option_map[Architecture] == Arch::X86_64
								
								when Arch::FreeStanding
									options.concat ['-ffreestanding', '-nostdlib']
								
								when Arch::RedZone
									options << '-mno-red-zone' unless value
								
								when Languages::C::Includes
									options.concat value.map { |path| "-I#{path}" }
								
								when Languages::C::Defines
									value.each_pair { |key, value| options << "-D#{key}#{"=#{value}" if value}" }
							end
						end
						
						Builder.execute "#{option_map[Prefix]}#{lang.last}", *options, '-x', *lang.first, '-pipe', stop, node.filename, '-o', output
					end
				end
				
				class Preprocessor < Processor
					link Assembly::WithCPP => Assembly
					
					def self.convert(node, target)
						node.cache(target, [Prefix]) do |output, option_map|
							Builder.execute "#{option_map[Prefix]}#{GCC}", '-x', 'assembler-with-cpp', '-pipe', '-E', node.filename, '-o', output
						end
					end
				end
			end
			
			class Linker < Processor
				merger [ObjectFile] => [Executable, SharedLibrary]
				
				Script = FileOption.new
				PageSize = Option.new
				
				Options = [
					Architecture,
					LinkTimeOptimization,
					Prefix,
					Script,
					PageSize,
					Libraries,
					StaticLibraries,
					Arch::FreeStanding
				]
				
				def self.merge(package, nodes, target)
					package.cache_collection(nodes, target, Options) do |output, option_map|
						options = ['-L.']
						use_linker = false
						executable = GCC
						linker_options = []
						frontend_options = []
						libraries = []
						executable = GXX if nodes.find { |node| node.origin.class == Languages::CXX::File }
						
						option_map.each_pair do |option, value|
							case option
								when Architecture
									if value == Arch::X86
										frontend_options << '-m32'
									elsif value == Arch::X86_64
										frontend_options << '-m64'
									end
								
								when LinkTimeOptimization
									options << '-flto' if value
								
								when Arch::FreeStanding
									use_linker = true
								
								when Script
									linker_options.concat ['-T', value]
								
								when PageSize
									linker_options.concat ['-z', "max-page-size=#{value}"]
								
								when Libraries
									value.each do |library|
										if ::File.dirname(library) != '.'
											options << "-L#{::File.dirname(library)}"
											library = ::File.basename(library)
										end
										libraries << "-l#{library}"
									end
									
								when StaticLibraries
									options << '-static' if value
							end
						end
						
						if use_linker
							executable = LD
							options.concat linker_options
						else
							options.concat frontend_options
							linker_options.each do |option|
								options << '-Xlinker' << option
							end
						end
						
						options << '-shared' if target == SharedLibrary
						
						Builder.execute "#{option_map[Prefix]}#{executable}", *options, *nodes.map { |node| node.filename }, *libraries, '-o', output
					end
				end
			end
			
			class Archiver < Processor
				merger [ObjectFile] => StaticLibrary
				
				def self.merge(package, nodes, target)
					package.cache_collection(nodes, target, [Prefix]) do |output, option_map|
						Builder.execute("#{option_map[Prefix]}#{AR}", 'rsc', output, *nodes.map { |node| node.filename })
					end
				end
			end
			
			def self.locate(package, name)
				options = package.state.map_options [Prefix]
				Builder.capture "#{options[Prefix]}#{name}", '--version'
				true
			rescue Errno::ENOENT
				false
			end
			
			def self.use_component(package)
				Assembler.use_component(package) if locate(package, AS)
				if locate(package, GCC)
					Compiler.use_component(package)
					Compiler::Preprocessor.use_component(package)
				end
				Linker.use_component(package) if locate(package, LD)
				Archiver.use_component(package) if locate(package, AR)
			end
		end
	end
end
