module Reno
	class File < Node
		Extension = HashOption.new
		
		class CreationError < StandardError
		end
		
		def self.register(type, *args)
			case type
				when :ext
					ext = args[0]
					@ext = ext
			end
		end
		
		def self.ext(dot = true)
			dot ? (@ext ? ".#{@ext}" : "") : @ext 
		end
		
		attr_reader :filename
		
		def initialize(filename, state, digest = nil)
			@filename = filename
			@digest = digest
			super(state)
		end
		
		def copy(path)
			Builder.readypath(path)
			FileUtils.copy(@filename, path)
			self.class.new(path, @state, @digest)
		end
		
		def digest
			@digest ||= Digest.from_file(@filename).update_node(self.class)
		end
		
		def inspect
			"#<#{self.class} filename=#{@filename.inspect}>"
		end
	end
end