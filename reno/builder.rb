require 'pathname'
require 'fileutils'

module Reno
	class Builder
		attr_reader :sources, :cache, :sqlcache, :lock, :base
		attr :conf, true
		
		def self.readydirs(base, path)
			FileUtils.makedirs(File.dirname(File.expand_path(path, base)))
		end
		
		def self.cleanpath(base, path)
			Pathname.new(File.expand_path(path)).relative_path_from(base).to_s
		end
		
		def initialize(package)
			@package = package
			@base = @package.base
			@sources = []
			@lock = Mutex.new
		end
		
		def run(threads = 8)
			# Creates an unique list of the files
			base = Pathname.new(@package.base).cleanpath
			@files = FileList[*@sources].to_a.map { |file| Builder.cleanpath(base, file) }.uniq
			
			@cache = {}			
			@sqlcache = Cache.new(base)
			
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
		
		def work
			while filename = @files.pop
				file = SourceFile.new(self, filename)
				if file.modified?
					puts "Updating #{filename}..."
				end
			end
		end
	end
end