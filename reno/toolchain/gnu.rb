module Reno
	module Toolchain
		module GNU
			class Compiler < Processor
				def self.use_component(components)
					super
				end
			end
			
			Compiler.link Languages::C::File => ObjectFile
			
			class Linker < Processor
				def self.use_component(components)
					super
				end
				
				def self.eval_merge(nodes, target)
					eval_merge_simple(nodes, ObjectFile, target)
				end
			end
			
			Linker.merger Executable, SharedLibrary, StaticLibrary
			
			def self.use_component(components)
				Compiler.use_component(components)
				Linker.use_component(components)
			end
		end
	end
end
