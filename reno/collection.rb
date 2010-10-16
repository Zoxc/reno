module Reno
	class Collection
		class CollectionError < StandardError
		end
		
		class NodeTypeMap
			def initialize
				@map = {}
			end
			
			def get(node, &block)
				key = [node.class, node.state]
				result = @map[key]
				return result if result
				@map[key] = block.call(node.class, node.state)
			end
			
			def paths
				@map.values
			end
		end
		
		attr_reader :package, :nodes
		
		def initialize(package)
			@package = package
			@nodes = []
		end
		
		def collect(*patterns)
			patterns.each do |pattern|
				files = Dir.glob(pattern)
				files.each do |file|
					file = @package.cache.file_by_path(file, @package.state, :collect)
					# skip to the next file or raise an error?
					# raise CollectionError, "Unable to collect file '#{file}', could not identifiy the extension '#{ext}'" unless fileclass
					next unless file
					@nodes << file
				end
			end
		end
		
		def path_combinations(sets, &block)
			results = []
			indices = [0] * sets.size
			sizes = sets.map { |set| set.results.size }
			count = sets.size
			while true do
				combination = (0...count).map { |i| sets[i].results[indices[i]] }
				results << combination if block.call(combination)
				indices[0] += 1;
				i = 0
				while indices[i] >= sizes[i] do
					indices[i] = 0
					i += 1
					return results if i == count
					indices[i] += 1
				end
			end
			nil
		end
		
		def verify_combination?(combination)
			# Walk backwards and make sure all links are the same. Return true if the same merge link is found on all paths.
			size = -(combination.min { |path| path.size }.size)
			index = -1
			while index >= size
				first = combination.first[index]
				combination.each do |path|
					return false unless path[index].eql?(first)
				end
				return true if Node::MergeLink === first
				index -= 1
			end
			false
		end
		
		class TreeNode
			attr_reader :children
			
			def initialize(parent)
				parent.children << self if parent
				@parent = parent
				@children = []
			end
			
			def print(indent = 0)
				puts "#{"   " * indent}> #{to_s}"
				indent += 1
				@children.each { |child| child.print(indent) }
			end
			
			def cost
				@children.reduce(0) { |cost, child| cost + child.cost }
			end
			
			def run(package)
				result = []
				@children.each { |child| result.concat child.run(package) }
				result
			end
		end
		
		class MergeTreeNode < TreeNode
			attr_reader :children
			
			def initialize(parent, link, path)
				super(parent)
				@link = link
				@path = path
			end
			
			def to_s
				"#{@link.inspect} - #{@path.inspect}"
			end
			
			def cost
				super + @path.size + 1
			end
			
			def run(package)
				output = @link.process(package, super)
				[Node::PathResult.follow(output, @path)]
			end
		end
		
		class PathTreeNode < TreeNode
			attr_reader :children
			
			def initialize(parent, path, path_result)
				super(parent)
				@path_result = path_result
				@path = path
			end
			
			def to_s
				"#{@path_result.inspect} - #{@path.inspect}"
			end
			
			def cost
				@path.size
			end
			
			def run(package)
				@path_result.nodes.map do |node|
					Node::PathResult.follow(node, @path)
				end
			end
		end
		
		def build_tree(node, paths, index, stop, size)
			if index < size
				#puts "#done(#{index}:#{stop}:#{size}):"
				paths.each do |path|
					PathTreeNode.new(node, path[0][0..stop], path[1])
					#puts "\t#{path[0][0..stop].inspect} - #{path[1].inspect}"
				end
				return
			end
			#puts "#following(#{index}:#{stop}:#{size}):"
			#paths.each do |path|
			#	puts "\t#{path[0][0..stop].inspect} - #{path[1].inspect}"
			#end
			paths.group_by { |path| link = path[0][index]; (Node::MergeLink === link) && link }.each_pair do |link, paths|
				if link
					post_merge = index == -1 ? [] : paths[0][0][(index + 1)..stop]
					#puts "#merge(#{index}:#{stop}:#{size}):"
					#puts "\t#{link.inspect} :: #{post_merge.inspect}"
					paths.reject! { |path| path[0].empty? }
					#puts "#branch(#{index}:#{stop}:#{size}):"
					#paths.each do |new_path|
					#	puts "\t#{new_path[0][0...index].inspect} - #{new_path[1].inspect}"
					#end
					build_tree(MergeTreeNode.new(node, link, post_merge), paths, index - 1, index - 1, size)
					#puts "#done-branch(#{index}:#{stop}:#{size}):"
				else
					#puts "#pass(#{index}:#{stop}:#{size}):"
					#paths.each do |path|
					#	puts "\t#{path[0][0..stop].inspect} - #{path[1].inspect}"
					#end
					build_tree(node, paths, index - 1, stop, size)
				end
			end
		end
		
		def merge(target)
			map = NodeTypeMap.new
			
			@nodes.each do |node|
				path = map.get(node) do |type, state|
					result = type.path(@package, state, target)
					raise "Unable to merge #{type} to #{target}" if result.empty?
					result
				end
				path.nodes << node
			end
			
			paths = map.paths
			
			collection = Collection.new(package)
			
			if paths.size > 0
				# Find all the valid combinations
				combinations = path_combinations(paths) do |combination|
					# combination.each{ |paths| puts "Paths: #{paths.inspect}" }
					# verify_combination? doesn't work if any array is empty
					verify_combination?(combination)
				end
				
				raise "Unable to merge #{@nodes.map { |node| node.class.name }.uniq.join(', ')} to #{target}" if combinations.empty?
				
				trees = combinations.map do |combination|
					size = combination.max { |path| path.size }.size
					zipped = combination.zip(paths)
					#puts "building tree: #{zipped.inspect}"
					tree = TreeNode.new(nil)
					build_tree(tree, zipped, -1, -1, -size)
					tree
				end
				
				tree = trees.min_by { |tree| tree.cost }
				
				collection.nodes.concat(tree.run(@package))
			end
			
			collection
		end
		
		def <<(node)
			@nodes << node
			self
		end
		
		def +(other)
			collection = Collection.new(@package)
			collection.nodes.concat(@nodes)
			collection.nodes.concat(other.nodes)
			collection
		end
		
		def &(other)
			collection = Collection.new(@package)
			collection.nodes.concat(@nodes)
			
			other.nodes.each do |node|
				next if @nodes.find { |local| local.filename == node.filename }
				collection.nodes << node
			end
			
			collection
		end
		
		def convert(target)
			collection = Collection.new(@package)
			map = NodeTypeMap.new
			nodes = @nodes.map do |node|
				path_result = map.get(node) do |type, state|
					result = type.path(nil, state, target)
					raise "Unable to convert #{type} to #{target}" if result.empty?
					result
				end
				{node: node, path: path_result}
			end
			collection.nodes.concat(nodes.map { |pair| pair[:path].follow(pair[:node]) })
			collection
		end
		
		def name(name, ext = true)
			collection = Collection.new(@package)
			if @nodes.size == 1
				collection << @nodes.first.copy("#{name}#{if ext; @nodes.first.class.ext end}")
			else
				@nodes.each_with_index do |node, index|
					collection << node.copy("#{name}-#{index + 1}#{if ext; node.class.ext end}")
				end
			end
			collection
		end
		
		def inspect
			"#<#{self.class} nodes=#{@nodes}>"
		end
	end
end