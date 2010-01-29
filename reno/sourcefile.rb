require 'digest/md5'

module Reno
	class SourceFile
		def self.locate(builder, filename)
			builder.synchronize do
				return builder.cache[:filename] || new(builder, filename)
			end
		end
		
		def initialize(builder, filename)
			@builder = builder
			@filename = filename
			@builder.cache[:filename] = self
			@db = @builder.sqlcache.db
		end
		
		def digest
			content = File.open(File.join(@builder.base, @filename), 'rb') { |f| f.read }
			Digest::MD5.hexdigest(content)
		end
		
		def get_dependencies
			#@dependencies = cache.db.from(:dependencies).filter(:file => row[:id])
		end
		
		def modified?
			row = @db[:files][:name => @filename]
			
			if row
				@id = row[:id]
				md5 = digest
				
				if row[:md5] != md5 then
					@builder.sqlcache.update_md5(@id, md5)
					@builder.sqlcache.clear_dependencies(@id)
					get_dependencies
					return true
				end
			else
				@id = @db[:files].insert(:name => @filename, :md5 => digest)
				get_dependencies
				true
			end
		end
		
		def from_file(file)
			@file = file
			setup cache.db.from(:files)[:name => file]
		end
		
		def setup(row)
			if row
				@modified = false
				old_md5 = @row[:md5]
				md5 = Digest::MD5.hexdigest(File.read(@file, 'rb'))
				if @old_md5 != @md5 then
					@modified = true
					return
				end
				#@dependencies = cache.db.from(:dependencies).filter(:file => row[:id])
			else
				@modified = true
			end
		end
	end
end