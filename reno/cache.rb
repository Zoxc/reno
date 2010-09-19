module Reno
	class Cache
		def initialize(path)
			@path = path
			Builder.readydir(path)
		end
		
		def place(node, target, digest)
			::File.join @path, "#{target.node_name}-#{digest.to_hex}#{target.ext ? '.' : ''}#{target.ext}"
		end
		
		def cache(node, target, &block)
			digest = node.digest.dup.update_node(target)
			filename = place(node, target, digest)
			unless ::File.exists?(filename)
				block.call(filename)
			end
			target.new(filename, node.state, digest)
		end
	end
end