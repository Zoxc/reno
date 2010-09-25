module Reno
	class Cache
		def initialize(path)
			@path = path
			Builder.readydir(path)
		end
		
		def place(target, digest)
			::File.join @path, "#{target.node_name}-#{digest.to_hex}#{target.ext}"
		end
		
		def cache(node, target, option_set = nil, &block)
			option_map = option_set && node.state.map_options(option_set)
			digest = node.digest.dup
			digest.update(target)
			digest.update(option_map)
			filename = place(target, digest)
			unless ::File.exists?(filename)
				block.call(filename, option_map)
			end
			target.new(filename, node.state, digest)
		end
		
		def cache_collection(collection, target, option_set = nil, &block)
			option_map = option_set && collection.package.state.map_options(option_set)
			digest = Digest.new
			collection.nodes.each do |node|
				digest.update(node.digest)
			end
			digest.update(target)
			digest.update(option_map)
			filename = place(target, digest)
			unless ::File.exists?(filename)
				block.call(filename, option_map)
			end
			target.new(filename, collection.package.state, digest)
		end
	end
end