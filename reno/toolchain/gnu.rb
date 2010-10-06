module Reno
	module Toolchain
		module GNU
			Prefix = Option.new
			
			class Assembler < Processor
				link Assembly => ObjectFile
				
				def self.convert(node, target)
					node.cache(target, [Prefix]) do |output, option_map|
						Builder.execute "#{option_map[Prefix]}as", node.filename, '-o', output
					end
				end
			end
			
			class Compiler < Processor
				link [Languages::C::File, Languages::CXX::File] => [ObjectFile, Assembly]
				
				Options = [
					Prefix,
					Architecture,
					Optimization,
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
						stop = if target == ObjectFile
							'-c'
						elsif target == Assembly
							'-S'
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
							end
						end
						
						Builder.execute "#{option_map[Prefix]}gcc", *options, '-x', *lang.first, '-pipe', stop, node.filename, '-o', output
					end
				end
				
				class Preprocessor < Processor
					link Assembly::WithCPP => Assembly
					
					def self.convert(node, target)
						node.cache(target, [Prefix]) do |output, option_map|
							Builder.execute "#{option_map[Prefix]}gcc", '-x', 'assembler-with-cpp', '-pipe', '-E', node.filename, '-o', output
						end
					end
				end
			end
			
			class Linker < Processor
				merger [ObjectFile] => [Executable, SharedLibrary]
				
				Script = FileOption.new
				PageSize = Option.new
				
				def self.merge(package, nodes, target)
					package.cache_collection(nodes, target, [Prefix, Script, PageSize]) do |output, option_map|
						script = if option_map[Script]; ['-T', option_map[Script]] end
						page_size = if option_map[PageSize]; ['-z', "max-page-size=#{option_map[PageSize]}"] end
						shared = if target == SharedLibrary; '-shared' end
						Builder.execute "#{option_map[Prefix]}ld", *script, *page_size, *shared, *nodes.map { |node| node.filename }, '-o', output
					end
				end
			end
			
			class Archiver < Processor
				merger [ObjectFile] => StaticLibrary
				
				def self.merge(package, nodes, target)
					package.cache_collection(nodes, target, [Prefix]) do |output, option_map|
						Builder.execute("#{option_map[Prefix]}ar", 'rsc', output, *nodes.map { |node| node.filename })
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
				Assembler.use_component(package) if locate(package, 'as')
				if locate(package, 'gcc')
					Compiler.use_component(package)
					Compiler::Preprocessor.use_component(package)
				end
				Linker.use_component(package) if locate(package, 'ld')
				Archiver.use_component(package) if locate(package, 'ar')
			end
		end
	end
end
