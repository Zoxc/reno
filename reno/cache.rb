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
		
		def setup_table(name, &block)
			@db.create_table(name, &block) unless @db.table_exists?(name)
		end
		
		def initialize(builder)
			@db = Sequel.sqlite(:database => builder.output('cache.db'))
			
			setup_table :files do
				primary_key :id, :type => Integer
				String :name
				String :md5
				String :output
				FalseClass :dependencies
			end
			
			setup_table :dependencies do
				Integer :file
				Integer :dependency
			end
			
			Languages.constants.each do |language|
				language = Languages.const_get(language)
				
				next if language.superclass != Languages::Language
				
				language.setup_schema(self)
			end
		end
	end
end