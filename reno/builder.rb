require 'pathname'
require 'fileutils'

module Reno
	class Builder
		attr_reader :sources, :cache, :sqlcache, :lock, :base, :output
		attr :conf, true
		
		def self.readydirs(path)
			FileUtils.makedirs(File.dirname(path))
		end
		
		def self.cleanpath(base, path)
			Pathname.new(File.expand_path(path)).relative_path_from(Pathname.new(base)).to_s
		end
		
		def self.execute(command, *args)
			#puts [command, *args].join(' ')
			IO.popen([command, *args]) do |f|
				f.readlines
			end
			raise "#{command} failed with error code #{$?.exitstatus}" if $?.exitstatus != 0
		end
		
		def self.capture(command, *args)
			#puts [command, *args].join(' ')
			result = nil
			IO.popen([command, *args]) do |f|
				result = f.readlines.join('')
			end
			raise "#{command} failed with error code #{$?.exitstatus}" if $?.exitstatus != 0
			result
		end
	 
		def self.clean(filename)
			if File.exists?(filename)
				File.delete(filename)
				begin
					dir = File.dirname(filename)
					while File.exists?(dir)
						Dir.rmdir(dir)
						dir = File.dirname(dir)
					end
				rescue SystemCallError
				end
			end
		end
		
		def puts(*args)
			@puts_lock.synchronize do
				Kernel.puts *args
			end
		end
		
		def output(file)
			result = File.expand_path(File.join(@output, file), @base)
			Builder.readydirs(result)
			result
		end
		
		def initialize(package)
			@package = package
			@base = @package.base
			@output = @package.output
			@sources = []
			@lock = Mutex.new
			@puts_lock = Mutex.new
			@files_lock = Mutex.new
			@cache = {}		
		end
		
		def run(threads = 8)
			# Creates an unique list of the files
			@files = FileList[*@sources].to_a.map { |file| Builder.cleanpath(@base, file) }.uniq
		
			@sqlcache = Cache.new(self)
			
			# Start worker threads	
			workers = []
			threads.times do
				workers << Thread.new do
					work
				end
			end
			
			# Wait for all the workers
			workers.each { |worker| worker.join }
		end
		
		def get_file
			@files_lock.synchronize do
				@files.pop
			end
		end
		
		def work
			while filename = get_file
				SourceFile.locate(self, filename).build
			end
		end
	end
end