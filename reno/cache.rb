module Reno
	class Cache
		Database = 'cache.db'
		def initialize(path)
			@path = path
			Builder.readydir(path)
			db_path = ::File.join(path, Database)
			new_db = !::File.exists?(db_path)
			@db = Sequel.sqlite(:database => db_path)
			if new_db
				@db.create_table :cached do
					primary_key :id
					String :sha
					String :path
					Integer :session
					Integer :attempt
				end
				
				@db.create_table :session do
					Integer :id
				end
			end
			
			@cached = @db[:cached]
			sessions = @db[:session]
			sessions.insert(id: 0) if new_db
			@session = sessions.first[:id] + 1
			sessions.update(id: @session)
		end
		
		def free_path(free_path, free_id)
			# find the entry that has this filename
			entry = @cached.filter(path: free_path).first
			return unless entry
			
			# return if we're already using this entry
			return if entry[:id] == free_id
			
			# setup variables
			path = entry[:path]
			ext = ::File.extname(path)
			base = path[0...-ext.size]
			attempt = entry[:attempt]
			base.chomp!("-#{attempt}") if attempt != 0
			
			# find a free filename so we can rename this entry
			begin
				attempt += 1
				new_path = "#{base}-#{attempt}#{ext}"
			end while @cached.filter(path: new_path).count > 0
			
			# rename this entry and update the database
			::File.rename(::File.join(@path, path), ::File.join(@path, new_path))
			@cached[id: entry[:id]] = {attempt: attempt, path: new_path}
		end
		
		def place(path, target, digest, &block)
			# make a filename for this file
			result = "#{path}#{target.ext}"
			result = '_' + result if result == Database
			
			sha = digest.to_hex
			
			# the values an entry should have
			hash = {attempt: 0, session: @session, path: result, sha: sha}
			
			# check if there's a entry for this already
			entry = @cached.filter(sha: sha).first
			
			# make sure the filename is free
			free_path(result, entry ? entry[:id] : nil)
			
			# build the final path and create required directories
			final = Builder.readypath(::File.join(@path, result))
			
			if entry
				# rename the existing file if it doesn't match with our result
				if result != entry[:path]
					::File.rename(::File.join(@path, entry[:path]), final)
				end
				
				# update the database with the new filename and session
				@cached[id: entry[:id]] = hash;
			else
				# generate the new file
				block.call(final)
				
				# the next step should not be executed if the generation failed

				# insert the entry into the database
				@cached.insert(hash)
			end
			
			final
		end
		
		def purge
			# delete all entries which does not have the current session id
			dataset = @cached.exclude(session: @session)
			dataset.each { |entry| ::File.delete(::File.join(@path, entry[:path])) }
			dataset.delete
		end
		
		def cache(node, target, option_set = nil, &block)
			option_map = option_set && node.state.map_options(option_set)
			digest = node.digest.dup
			digest.update(target)
			digest.update(option_map)
			filename = place(node.origin, target, digest) do |filename|
				block.call(filename, option_map)
			end
			target.new(filename, node.state, digest, node.origin)
		end
		
		def cache_collection(package, nodes, target, option_set = nil, &block)
			option_map = option_set && package.state.map_options(option_set)
			digest = Digest.new
			nodes.each do |node|
				digest.update(node.digest)
			end
			digest.update(target)
			digest.update(option_map)
			filename = place(target.node_name, target, digest) do |filename|
				block.call(filename, option_map)
			end
			target.new(filename, package.state, digest)
		end
	end
end