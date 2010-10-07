module Reno
	module Toolchain
		module LLVM
			Target = Option.new
			
			class Bytecode < File
				register :ext, 'll'
			end
			
			class BinaryBytecode < File
				register :ext, 'bc'
			end
			
			class Clang < Processor
				# Add Assembly here when Clang supports -march and -mtriple
				link [Languages::C::File, Languages::CXX::File] => [BinaryBytecode]
				
				Options = [
					Target,
					Architecture,
					Optimization,
					Exceptions,
					Arch::X86::Enable3DNow,
					Arch::X86::MMX,
					Arch::X86::SSE,
					Arch::X86::SSE2,
					Arch::X86_64::MemoryModel,
					Arch::FreeStanding,
					Arch::RedZone,
					Languages::C::Standard,
					Languages::CXX::Standard
				]
				
				def self.convert(node, target)
					node.cache(target, Options) do |output, option_map|
						target_opt = if target == BinaryBytecode
							['-c', '-emit-llvm']
						elsif target == Assembly
							['-S']
						else
							raise "Unknown target #{target}"
						end
						
						lang = case node
							when Languages::C::File
								['c', Languages::C::Standard]
								
							when Languages::CXX::File
								['c++', Languages::CXX::Standard]
							else
								raise "Unknown language #{node.class.node_name}"
						end
						
						options = []
						
						options << "-std=gnu#{option_map[lang.last][1..-1]}" if option_map.present? lang.last
						
						option_map.each_pair do |option, value|
							case option
								when Architecture
									if value == Arch::X86
										options << '-m32'
									elsif value == Arch::X86_64
										options << '-m64'
									end
								
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
								
								when Exceptions
									options << "-f#{"no-" if value == :none}exceptions"
								
								when Arch::X86::Enable3DNow
									options << "-m#{"no-" unless value}3dnow" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86::MMX
									options << "-m#{"no-" unless value}mmx" if option_map[Architecture] <= Arch::X86
									
								when Arch::X86::SSE
									options << "-m#{"no-" unless value}sse" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86::SSE2
									options << "-m#{"no-" unless value}sse2" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86_64::MemoryModel
									options << "-mcmodel=#{value}" if option_map[Architecture] <= Arch::X86_64
								
								when Arch::FreeStanding
									options.concat ['-ffreestanding', '-nostdlib']
								
								when Arch::RedZone
									options << '-mno-red-zone' unless value
							end
						end
						
						Builder.execute 'clang', *options, '-x', *lang.first, '-pipe', *target_opt, node.filename, '-o', output
					end
				end
				
				class Preprocessor < Processor
					link Assembly::WithCPP => Assembly
					
					def self.convert(node, target)
						node.cache(target) do |output|
							Builder.execute 'clang', '-x', 'assembler-with-cpp', '-E', node.filename, '-o', output
						end
					end
				end
			end
			
			class Disassembler < Processor
				link BinaryBytecode => Bytecode
				
				def self.convert(node, target)
					node.cache(target) do |output|
						Builder.execute 'llvm-dis', "-o=#{output}", node.filename
					end
				end
			end
			
			class Compiler < Processor
				link BinaryBytecode => Assembly
				
				Options = [
					Target,
					Architecture,
					Optimization,
					Arch::X86::Enable3DNow,
					Arch::X86::MMX,
					Arch::X86::SSE,
					Arch::X86::SSE2,
					Arch::RedZone,
					Arch::X86_64::MemoryModel,
				]
				
				def self.convert(node, target)
					node.cache(target, Options) do |output, option_map|
						options = []
						
						option_map.each_pair do |option, value|
							case option
								when Target
									options.concat ['-mtriple', value.gsub('_', '-')]
								
								when Architecture
									options.concat ['-march', value.name.gsub('_', '-')]
								
								when Optimization
									options.concat(case value
										when :none
											[]
										when :speed
											['-O3']
										when :balanced
											['-O2']
										when :size
											['-O2']
									end)
								
								when Arch::X86::Enable3DNow
									options << "-mattr=#{"-" unless value}3dnow" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86::MMX
									options << "-mattr=#{"-" unless value}mmx" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86::SSE
									options << "-mattr=#{"-" unless value}sse" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86::SSE2
									options << "-mattr=#{"-" unless value}sse2" if option_map[Architecture] <= Arch::X86
								
								when Arch::X86_64::MemoryModel
									options << "-code-model=#{value}" if option_map[Architecture] == Arch::X86_64
								
								when Arch::RedZone
									options << '-disable-red-zone' unless value
							end
						end
						
						Builder.execute 'llc', *options, node.filename, '-o', output
					end
				end
			end
			
			class Linker < Processor
				merger [BinaryBytecode] => BinaryBytecode
				
				def self.merge(package, nodes, target)
					package.cache_collection(nodes, target) do |output|
						Builder.execute 'llvm-link', *nodes.map { |node| node.filename }, '-o', output
					end
				end
			end
			
			def self.locate(package, name)
				#Builder.capture name, '--version'
				true
			rescue Errno::ENOENT
				false
			end
			
			def self.use_component(package)
				if locate(package, 'clang')
					Clang.use_component(package)
					Clang::Preprocessor.use_component(package)
				end
				Disassembler.use_component(package) if locate(package, 'llvm-dis')
				Compiler.use_component(package) if locate(package, 'llc')
				Linker.use_component(package) if locate(package, 'llvm-link')
			end
		end
	end
end
