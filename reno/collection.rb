module Reno
	class Collection
		class CollectionError < StandardError
		end
		
		attr_reader :package, :nodes
		
		def initialize(package)
			@package = package
			@nodes = []
		end
		
		def collect(*patterns)
			patterns.each do |pattern|
				ext = ::File.extname(pattern)[1..-1]
				exts = @package.state.get_option File::Extension
				fileclass = exts[ext.downcase]
				raise CollectionError, "Unable to use pattern '#{pattern}', could not identifiy the extension '#{ext}'" unless fileclass
				files = Dir.glob(pattern)
				@nodes.concat(files.map { |file| fileclass.new(file, @package.state) })
			end
		end
		
		def cache(target, option_set = nil, &block)
			@package.cache.cache_collection(self, target, option_set, &block)
		end
		
		def merge(target)
			mergers = target.mergers
			action = nil
			if mergers
				merge_actions = []
				mergers.each do |merger|
					next unless @package.state.get_processor(merger)
					merge_action = merger.eval_merge(self, target)
					next unless merge_action
					merge_actions << merge_action
				end
				action = merge_actions.find_all.min
			end
			
			raise "Unable to find a merger for #{target}." unless action
			
			collection = Collection.new(@package)
			collection << action.run
		end
		
		def <<(node)
			@nodes << node
			self
		end
		
		def convert(target)
			collection = Collection.new(package)
			nodes = @nodes.map do |node|
				path_result = node.path(target)
				raise "Unable to convert #{node} to #{target}" unless path_result
				{node: node, path: path_result}
			end
			collection.nodes.concat(nodes.map { |pair| pair[:path].follow(pair[:node]) })
			collection
		end
		
		def name(name)
			if @nodes.size == 1
				@nodes.first.copy "#{name}#{@nodes.first.class.ext}"
			else
				@nodes.each_with_index do |node, index|
					node.copy "#{name}-#{index + 1}#{node.class.ext}"
				end
			end
		end
		
		def inspect
			"#<#{self.class} nodes=#{@nodes}>"
		end
	end
end