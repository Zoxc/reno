require 'pathname'
require 'fileutils'

module Reno
	class BuilderError < StandardError
	end
	
	class Builder
		attr_reader :sources, :cache, :sqlcache, :base, :output, :objects, :package, :conf, :library, :dependencies, :output_name
		attr :conf, true

		def self.readydirs(path)
			FileUtils.makedirs(File.dirname(path))
		end
		
		def self.cleanpath(base, path)
			Pathname.new(File.expand_path(path)).relative_path_from(Pathname.new(base)).to_s
		end
		
		def self.execute(command, *args)
			puts [command, *args].join(' ')
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
			result = File.expand_path(file, @bulid_base)
			Builder.readydirs(result)
			result
		end
		
		def initialize(package, library, dependencies, conf)
			@dependencies = dependencies
			@library = library
			@package = package
			@changed = Lock.new
			@conf = conf
			@base = @package.base
			@bulid_base = File.expand_path(@package.output, @base)
			@objects = Lock.new([])
			@files = Lock.new([])
			@puts_lock = Mutex.new
			@cache =  Lock.new({})
			@output_name = output(@package.output_name(self))
		end
		
		def run(threads = 8)
			# Creates an unique list of the files
			patterns = @conf.get(:patterns).map { |pattern| File.join(@base, pattern) }
			@files.value = Dir[*patterns].map { |file| Builder.cleanpath(@base, file) }.uniq
			
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
			
			# Normalize locks
			@objects = @objects.value
			
			# Link the package if it changed or the output doesn't exist
			
			if @changed.value || !File.exists?(@output_name)
				puts "Linking #{@package.name}..."
				
				# Find a toochain to link this package
				linker = @package.default[:linker]
				linker = Toolchains::Hash.values.first unless linker
				raise BuilderError, "Unable to find a linker to use." unless linker
				
				linker.link(self, @output_name)
			else
				puts "Nothing to do with #{@package.name}."
			end
		end
		
		def get_file
			@files.lock do |files|
				files.pop
			end
		end
		
		def output_file(result)
			@objects.lock do |output|
				output << result
			end
		end
		
		def work
			while filename = get_file
				file = SourceFile.locate(self, filename)
				rebuild = file.rebuild?
				if rebuild
					@changed.value = true
					file.build
				end
				output_file file
			end
		end
	end
end