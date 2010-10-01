module Reno
	class Builder
		def self.readydir(path)
			FileUtils.makedirs(path)
			path
		end
		
		def self.cleanpath(base, path)
			Pathname.new(::File.expand_path(path)).relative_path_from(Pathname.new(base)).to_s
		end
		
		def self.readypath(path)
			readydir(::File.dirname(path))
			path
		end
		
		def self.execute(command, *args)
			#puts [command, *args].join(' ')
			IO.popen([command, *args]) do |f|
				print f.read
			end
			raise "#{command} failed with error code #{$?.exitstatus}" if $?.exitstatus != 0
		end
		
		def self.capture(command, *args)
			#puts [command, *args].join(' ')
			result = nil
			IO.popen([command, *args]) do |f|
				result = f.read
			end
			raise "#{command} failed with error code #{$?.exitstatus}" if $?.exitstatus != 0
			result
		end
	end
end
