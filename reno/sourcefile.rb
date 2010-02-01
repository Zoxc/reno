require 'digest/md5'

module Reno
	class SourceFileError < StandardError
	end
	
	class SourceFile
		attr_reader :path, :name, :row
		
		def self.locate(builder, filename)
			builder.cache.lock do |cache|
				return cache[filename] || new(builder, filename, cache)
			end
		end
		
		def initialize(builder, filename, cache)
			@builder = builder
			@name = filename
			@path = File.expand_path(@name, @builder.base)
			@changed = Lock.new
			@language = Lock.new
			@compiler = Lock.new
			@output = Lock.new
			@content = Lock.new
			@digest = Lock.new
			cache[filename] = self
			@db = @builder.sqlcache.db
			@row = Cache::FileModel.new(@db[:files], @name) do
				{:name => @name, :md5 => digest, :dependencies => false, :output => nil}
			end
		end
		
		def find_language
			file_ext = File.extname(@name).downcase
			
			Languages.constants.map { |name| Languages.const_get(name) }.each do |language|
				next if language.superclass != Languages::Language
				
				if language.extensions.any? { |ext| ext == file_ext }
					return language
				end
			end
			
			raise SourceFileError, "Unable to find a language for the file '#{@name}'."
		end
		
		def digest
			@digest.value {	Digest::MD5.hexdigest(content) }
		end
		
		def content
			@content.value { File.open(@path, 'rb') { |f| f.read } }
		end
		
		def output
			@output.value { @builder.output(@name + '.o') }
		end
		
		def language
			@language.value { find_language }
		end
		
		def compiler
			@compiler.value { Toolchains.locate(language) }
		end
		
		def get_dependencies
			@builder.puts "Getting dependencies for #{@name}..."
			@db[:dependencies].filter(:file => @row[:id]).delete
			
			dependencies = compiler.get_dependencies(self)
			dependencies.each do |path|
				file = SourceFile.locate(@builder, Builder.cleanpath(@builder.base, path))
				@db[:dependencies].insert(:file => @row[:id], :dependency => file.row[:id])
			end
			
			@row[:dependencies] = true
		end
		
		def dependencies_changed?
			get_dependencies unless @row[:dependencies]
			
			dependencies = @db[:dependencies].filter(:file => @row[:id]).all
			
			dependencies.any? do |dependency|
				SourceFile.locate(@builder, @db[:files][:id => dependency[:dependency]][:name]).changed?
			end
		end
		
		def changed?
			@changed.value do |changed|
				changed = nil
				
				# Check if the file has changed and reset dependencies and output if needed
				if @row[:md5] != digest then
					@row[:dependencies] = false
					@row[:output] = nil
					@row[:md5] = digest
					changed = true
				else
					changed = dependencies_changed? ? true : false
				end

				@row[:output] = nil if changed
				
				changed
			end
		end
		
		def rebuild?
			return true unless @row[:output] and File.exists?(File.expand_path(@row[:output], @builder.base))
		
			changed?
		end
		
		def build
			@builder.puts "Compiling #{@name}..."
			compiler.compile(self)
			
			output = @output.value
			
			if File.exists? output
				@row[:output] = output
			else
				raise SourceFileError, "Can't find output '#{output}' from #{name}."
			end
		end
	end
end