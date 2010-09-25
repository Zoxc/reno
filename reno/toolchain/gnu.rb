module Reno
	module Toolchain
		module GNU
			class Assembler < Processor
				link Assembly => ObjectFile
				
				def self.convert(node, target)
					node.cache(target, Options) do |output, option_map|
						Builder.execute "#{option_map[Prefix]}as", node.filename, '-o', output
					end
				end
			end
			
			class Compiler < Processor
				link Languages::C::File => ObjectFile
				
				def self.convert(node, target)
					node.cache(target, Options) do |output, option_map|
						Builder.execute "#{option_map[Prefix]}gcc", '-x', 'c', '-pipe', '-c', node.filename, '-o', output
					end
				end
			end
			
			class Linker < Processor
				merger Executable, SharedLibrary
				
				def self.eval_merge(collection, target)
					eval_merge_simple(collection, ObjectFile, target)
				end
				
				def self.merge(collection, target)
					collection.cache(target, Options,) do |output, option_map|
						shared = if target == SharedLibrary; '-shared' end
						Builder.execute "#{option_map[Prefix]}ld", *shared, *collection.nodes.map { |node| node.filename }, '-o', output
					end
				end
			end
			
			class Archiver < Processor
				merger StaticLibrary
								
				def self.eval_merge(collection, target)
					eval_merge_simple(collection, ObjectFile, target)
				end
				
				def self.merge(collection, target)
					collection.cache(target, Options) do |output, option_map|
						Builder.execute("#{option_map[Prefix]}ar", 'rsc', output, *collection.nodes.map { |node| node.filename })
					end
				end
			end
			
			Prefix = Option.new
			Options = OptionSet.new [Prefix, Architecture]
			
			def self.locate(package, name)
				options = package.state.map_options(Options)
				Builder.capture "#{options[Prefix]}#{name}", '--version'
				true
			rescue Errno::ENOENT
				false
			end
			
			def self.use_component(package)
				Assembler.use_component(package) if locate(package, 'as')
				Compiler.use_component(package) if locate(package, 'gcc')
				Linker.use_component(package) if locate(package, 'ld')
				Archiver.use_component(package) if locate(package, 'ar')
			end
		end
	end
end
