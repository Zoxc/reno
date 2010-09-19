module Reno
	class Cache
		def initialize(path)
			@path = path
			Builder.readydir(path)
		end
		
		def place(target, digest)
			::File.join @path, "#{target.node_name}-#{digest.to_hex}#{target.ext}"
		end
		
		def cache(node, target, &block)
			digest = node.digest.dup.update_node(target)
			filename = place(target, digest)
			unless ::File.exists?(filename)
				block.call(filename)
			end
			target.new(filename, node.state, digest)
		end
		
		def cache_collection(collection, target, &block)
			digest = Digest.new
			collection.nodes.each do |node|
				digest.update_digest(node.digest)
			end
			digest.update_node(target)
			filename = place(target, digest)
			unless ::File.exists?(filename)
				block.call(filename)
			end
			target.new(filename, collection.package.state, digest)
		end
	end
end