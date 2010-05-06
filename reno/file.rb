module Reno
	class File < Node
		class Extension
			include Mergable
			
			attr_reader :map
			
			def initialize(ext, file)
				@map = {ext => file}
			end
			
			def locate(ext)
				@map[ext]
			end
			
			def merge(other)
				@map.merge!(other.map)
			end
		end
		
		class CreationError < StandardError
		end
		
		Conversions.register String do |pattern, state, settings|
			ext = ::File.extname(pattern)[1..-1]
			exts = state.get_component(File::Extension, true)
			fileclass = exts ? exts.locate(ext) : nil
			raise CreationError, "Unable to use pattern '#{pattern}', could identifiy the extension '#{ext}'" unless fileclass
			files = Dir.glob(pattern)
			files.map { |file| fileclass.new(file, fileclass, settings) }
		end
		
		attr_reader :filename
		
		def initialize(filename, node, settings)
			@filename = filename
			super(node, settings)
		end
		
		def inspect
			"#<Reno::File filename=#{@filename.inspect}>"
		end
	end
end