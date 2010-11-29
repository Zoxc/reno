module Reno
	class Digest
		def self.from_file(file)
			new.from_file(file)
		end
		
		attr_reader :digest
		
		def initialize
			@digest = ::Digest::SHA2.new(512)
		end
		
		def from_file(file)
			@digest.file file
			# File.open(path_to_file, 'r') do |file|
				# while buffer = file.read(1024)
					# @digest << buffer
				# end
			# end
			self
		end
		
		def update_node(node)
			@digest << node.node_name
			self
		end
		
		def update(data)
			case data
				when OptionMap
					data.update_digest(self)
				when Digest
					@digest << data.to_hex
				when Node
					@digest << data.class.node_name
				when String
					@digest << data
			end
			self
		end
		
		def to_hex
			@digest.hexdigest
		end
	end
end