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
		
		attr_reader :filename
		
		def initialize(filename, components)
			@filename = filename
			super(components)
		end
		
		def inspect
			"#<Reno::File filename=#{@filename.inspect}>"
		end
	end
		
	Conversions.register String do |pattern, components|
		ext = ::File.extname(pattern)[1..-1]
		exts = components.get_component(File::Extension, true)
		fileclass = exts ? exts.locate(ext) : nil
		raise CreationError, "Unable to use pattern '#{pattern}', could identifiy the extension '#{ext}'" unless fileclass
		files = Dir.glob(pattern)
		files.map { |file| fileclass.new(file, components) }
	end
end