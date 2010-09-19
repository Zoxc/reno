module Reno
	class Collection
		class CollectionError < StandardError
		end
		
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
		
		def merge(target)
			mergers = target.mergers
			processor = nil
			if mergers
				merge_actions = []
				mergers.each do |merger|
					next unless @package.state.get_processor(merger)
					merge_action = merger.eval_merge(@nodes, target)
					next unless merge_action
					merge_actions << merge_action
				end
				processor = merge_actions.find_all.min
			end
			
			raise "Unable to find a merger for #{target}." unless processor
			puts processor.inspect
		end
		
		def convert(target)
			@nodes.map do |node|
				path = node.path(target)
				raise "Unable to convert #{node} to #{target}" unless path
				path
			end.map do |path|
				path.follow
			end
		end
		
		def inspect
			"#<#{self.class} nodes=#{@nodes}>"
		end
	end
end