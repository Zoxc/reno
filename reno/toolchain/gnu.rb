module Reno
	module Toolchain
		module GNU
			class Compiler < Processor
				def self.use_component(package)
					super
				end
				
				def self.convert(node, target)
					node.cache(target) do |output|
						Builder.execute 'gcc', '-x', 'c', '-pipe', '-c', node.filename, '-o', output
					end
				end
			end
			
			Compiler.link Languages::C::File => ObjectFile
			
			class Linker < Processor
				def self.use_component(package)
					super
				end
				
				def self.eval_merge(nodes, target)
					eval_merge_simple(nodes, ObjectFile, target)
				end
			end
			
			Linker.merger Executable, SharedLibrary, StaticLibrary
			
			def self.use_component(package)
				Compiler.use_component(package)
				Linker.use_component(package)
			end
		end
	end
end
