require 'pathname'
require 'sequel'

module Reno
	class Cache
		attr_reader :base, :db
		
		class FileModel
			def initialize(db, name, &block)
				@db = db
				@row = @db[:name => name]
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
				@db.filter(:id => @row[:id]).update(name => value)
			end
		end
		
		def initialize(builder)
			@db = Sequel.sqlite(:database => builder.output('cache.db'))
			
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
	end
end