require 'pathname'
require 'sequel'

module Reno
	class Cache
		attr_reader :base, :db
		
		def initialize(base)
			@base = base
			db = File.join(@base, 'build/cache.db')
			Builder.readydirs(base, db)
			
			@db = Sequel.sqlite(:database => db)
			
			@db.create_table(:files) do
				primary_key :id
				String :name
				String :md5
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