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
			
			Options = OptionSet.new [Architecture]
			
			class Compiler < Processor
				link BinaryBytecode => Assembly
				
				def self.convert(node, target)
					node.cache(target, Options) do |output, option_map|
						arch = if option_map[Architecture]; ['-march', option_map[Architecture].gsub('_', '-')] end
						Builder.execute 'llc', *arch, node.filename, '-o', output
					end
				end
			end
			
			class Linker < Processor
				merger BinaryBytecode
				
				def self.eval_merge(collection, target)
					eval_merge_simple(collection, BinaryBytecode, target)
				end
				
				def self.merge(collection, target)
					collection.cache(target) do |output|
						Builder.execute 'llvm-link', *collection.nodes.map { |node| node.filename }, '-o', output
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
