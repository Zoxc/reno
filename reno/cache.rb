module Reno
	class Cache
		Database = 'cache.db'
		
		def initialize(path, source)
			@path = path
			@source = source
			Builder.readydir(path)
			db_path = ::File.join(path, Database)
			new_db = !::File.exists?(db_path)
			@db = Sequel.sqlite(:database => db_path)
			if new_db
				@db.create_table :sources do
					primary_key :id
					String :sha
					String :path
					String :type
					DateTime :date
					Boolean :checked_dependencies
				end
				
				@db.create_table :dependencies do
					primary_key :id
					Integer :source
					Integer :dependency
				end
				
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
			@files_by_path = {}
			@files_by_id = {}
			@cached = @db[:cached]
			@sources = @db[:sources]
			@dependencies = @db[:dependencies]
			sessions = @db[:session]
			sessions.insert(id: 0) if new_db
			@session = sessions.first[:id] + 1
			sessions.update(id: @session)
		end
		
		def class_from_path(path, state, mode)
			exts = state.get_option File::Extension
			ext = ::File.extname(path)[1..-1]
			file = exts[ext]
			unless file
				raise "Unable to import file '#{path}', could not identifiy the extension '#{ext}'" if mode == :require
				return
			end
			if file.collect?
				file
			else
				mode == :collect ? nil : file
			end
		end
		
		def create_file(id, filename, state, fileclass)
			file = fileclass.new(filename, state)
			file.set_source(id)
			
			@files_by_path[filename] = file
			@files_by_id[id] = file
		end
		
		def file_by_path(path, state, mode = nil, fileclass = nil)
			filename = Builder.cleanpath(@source, path)
			file = @files_by_path[filename]
			return file if file

			fileclass = class_from_path(path, state, mode) unless fileclass
			return unless fileclass
			
			entry = @sources[:path => filename]
			
			if entry
				id = entry[:id]
			else
				id = @sources.insert(path: filename, checked_dependencies: false, type: fileclass.node_name)
			end
			
			
			create_file(id, filename, state, fileclass)
		end
		
		def class_from_type(type)
			object = Reno
			type.split('.').each do |name|
				object = object.const_get(name)
			end
			raise "#{object.inspect} is not a file type" unless File > object
			object
		end
		
		def file_by_id(id, state, fileclass = nil)
			file = @files_by_id[id]
			return file if file
			
			entry = @sources[:id => id]
			raise "Unable to find file with id #{id}" unless entry
			
			filename = entry[:path]
			fileclass = class_from_type(entry[:type])
			
			create_file(id, entry[:path], state, fileclass)
		end
		
		def cache_dependencies(file, &block)
			checked = @sources[:id => file.id][:checked_dependencies]
			if checked
				@dependencies.filter(:source => file.id).map do |dependency|
					file_by_id(dependency[:dependency], file.state)
				end
			else
				result = block.call.map do |dependency|
					dependency = file_by_path(dependency.first, file.state, :require, dependency.last)
				end
				result.each do |dependency|
					@dependencies.insert(source: file.id, dependency: dependency.id)
				end
				@sources[id: file.id] = {checked_dependencies: true}
				result
			end
		end
		
		def cache_changes(file, path)
			filename = file.filename
			
			begin
				modified = ::File.mtime(filename)
			rescue StandardError => e
				File.missing_dependency(filename, path)
			end
			
			entry = @sources[:id => file.id]
			
			if !entry[:sha] || modified > entry[:date]
				sha = Digest.new.update(file.content).to_hex
				if sha != entry[:sha]
					@sources[id: entry[:id]] = {sha: sha, date: modified, checked_dependencies: false};
					
					# File has changed, reset dependencies
					@dependencies.filter(:source => file.id).delete
					file.invalidate_dependencies
				end
			else
				sha = entry[:sha]
			end
			
			Digest.new.update(sha)
		end
		
		def free_path(free_path, free_id)
			# find the entry that has this filename
			entry = @cached[:path => free_path]
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
			entry = @cached[:sha => sha]
			
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
			digest.update(option_map)
			digest.update_node(target)
			filename = place(node.origin.filename, target, digest) do |filename|
				puts "Converting #{node.origin.filename} from #{node.class.node_name} to #{target.node_name}"
				node.state.package.generate do
					block.call(filename, option_map)
				end
			end
			target.new(filename, node.state).set_origin(digest, node.origin)
		end
		
		def cache_collection(package, nodes, target, option_set = nil, &block)
			option_map = option_set && package.state.map_options(option_set)
			digest = Digest.new
			nodes.each do |node|
				digest.update(node.digest)
			end
			digest.update(option_map)
			digest.update_node(target)
			filename = place(target.node_name, target, digest) do |filename|
				puts "Merging #{nodes.map { |node| node.class.node_name }.uniq.join(', ')} to #{filename}"
				block.call(filename, option_map)
			end
			target.new(filename, package.state).set_origin(digest, nil)
		end
	end
end