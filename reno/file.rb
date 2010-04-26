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
		
		Conversions.register String do |filename, state|
			ext = ::File.extname(filename)[1..-1]
			exts = state.get_component(File::Extension, true)
			file = exts ? exts[ext] : nil
			raise CreationError, "Unable to use pattern '#{filename}', could identifiy the extension '#{ext}'" unless file
			file.new(filename, state)
		end
		
		attr_reader :filename
		
		def initialize(filename, state)
			@filename = filename
			super(state)
		end
	end
end