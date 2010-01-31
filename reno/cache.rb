require 'pathname'
require 'sequel'

module Reno
	class Cache
		attr_reader :base, :db
		
		class FileModel
			def initialize(db, name, &block)
				@db = db
				@row = @db[:name => @name]
				@changes = {}
				
				unless @row
					@row = block.call
					@row[:id] = @db.insert(@row)
				end
			end
			
			def [](name)
				@row[name]
			end
			
			def []=(name, value)
				@row[name] = value
				@changes[name] = value
			end
			
			def flush
				unless @changes.empty?
					@db.filter(:id => @row[:id]).update(@changes)
					@changes = {}
				end
			end
		end
		
		def initialize(base)
			@base = base
			db = File.expand_path('build/cache.db', @base)
			Builder.readydirs(base, db)
			
			@db = Sequel.sqlite(:database => db)
			
			@db.create_table(:files) do
				primary_key :id
				String :name
				String :md5
				String :output
				FalseClass :dependencies
			end unless @db.table_exists?(:files)
			
			@db.create_table(:dependencies) do
				primary_key :id, :type => Integer
				Integer :file
				Integer :dependency
			end unless @db.table_exists?(:dependencies)
		end
		
		def update_md5(id, md5)
		end
		
		def locate(file)
			@db.from(:files)[:name => file]
		end
	end
end