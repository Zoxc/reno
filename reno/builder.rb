module Reno
	class Builder
		def self.readydir(path)
			FileUtils.makedirs(path)
		end
		
		def self.readypath(path)
			readydir(::File.dirname(path))
		end
		
		def self.execute(command, *args)
			puts [command, *args].join(' ')
			IO.popen([command, *args]) do |f|
				f.readlines
			end
			raise "#{command} failed with error code #{$?.exitstatus}" if $?.exitstatus != 0
		end
		
		def self.capture(command, *args)
			puts [command, *args].join(' ')
			result = nil
			IO.popen([command, *args]) do |f|
				result = f.readlines.join('')
			end
			raise "#{command} failed with error code #{$?.exitstatus}" if $?.exitstatus != 0
			result
		end
	end
end
