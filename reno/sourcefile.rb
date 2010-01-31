require 'digest/md5'

module Reno
	class SourceFileError < StandardError
	end
	
	class SourceFile
		attr_reader :path, :name
		
		def self.locate(builder, filename)
			builder.lock.synchronize do
				return builder.cache[:filename] || new(builder, filename)
			end
		end
		
		def initialize(builder, filename)
			@builder = builder
			@name = filename
			@path = File.expand_path(@name, @builder.base)
			@changed_lock = Mutex.new
			@language_lock = Mutex.new
			@compiler_lock = Mutex.new
			@builder.cache[:filename] = self
			@db = @builder.sqlcache.db
			@row = Cache::FileModel.new(@db[:files], @name) do
				{:name => @name, :md5 => @builder.digest(@name), :dependencies => false, :output => nil}
			end
		end
		
		def lock
			yield self
		ensure	
			@row.flush
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
		
		def language
			@language_lock.synchronize do
				@language ||= find_language
			end
		end
		
		def compiler
			@compiler_lock.synchronize do
				@compiler ||= Compilers.locate(language.name)
			end
		end
		
		def get_dependencies
			@db[:dependencies].filter(:file => @row[:id]).delete
			
			
			puts language.inspect
			#puts language.get_dependencies(self).inspect
			#@dependencies = cache.db.from(:dependencies).filter(:file => row[:id])
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
			@changed_lock.synchronize do
				return @changed if @changed != nil
				
				# Check if the file has changed and reset dependencies if needed
				md5 = @builder.digest(@name)

				if @row[:md5] != md5 then
					@row[:dependencies] = false
					@row[:md5] = md5
					return true
				end

				@changed = dependencies_changed?
			end
		end
		
		def rebuild?
			return true unless @row[:output] and File.exists?(File.expand_path(@row[:output], @builder.base))
		
			changed?
		end
		
		def build
			if rebuild?
				compiler.compile(self)
			end
		end
	end
end