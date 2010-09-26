module Reno
	module Toolchain
		module LLVM
			class Bytecode < File
				register :ext, 'll'
			end
			
			class BinaryBytecode < File
				register :ext, 'bc'
			end
			
			class Clang < Processor
				link Languages::C::File => BinaryBytecode
				
				def self.convert(node, target)
					node.cache(target) do |output|
						Builder.execute 'clang', '-emit-llvm', '-c', node.filename, '-o', output
					end
				end
			end
			
			Target = Option.new
			
			class Compiler < Processor
				link BinaryBytecode => Assembly
				
				def self.convert(node, target)
					node.cache(target, [Target, Architecture]) do |output, option_map|
						arch = if option_map[Architecture]; ['-march', option_map[Architecture].gsub('_', '-')] end
						target = if option_map[Target]; ['-mtriple', option_map[Target].gsub('_', '-')] end
						Builder.execute 'llc', *target, *arch, node.filename, '-o', output
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
				Clang.use_component(package) if locate(package, 'clang')
				Compiler.use_component(package) if locate(package, 'llc')
				Linker.use_component(package) if locate(package, 'llvm-link')
			end
		end
	end
end
