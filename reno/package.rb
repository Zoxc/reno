module Reno
	class Package
		class State
			attr_reader :public, :private, :package
			
			def initialize(package, parent)
				@package = package
				@parent = parent
				@components = {}
				@public = Components.new(self)
				@private = Components.new(self)
			end
			
			def nodes(type = nil, private = true)
				(private ? @private : @public).nodes(type)
			end
			
			def use(components, args, block)
				result = []
				
				@package.state_block(block) do
					args.each do |component|
						result.concat(components.use(component))
					end
				end
				
				result.flatten!
				
				if result.empty?
					nil
				elsif result.size == 1
					result.first
				else
					result
				end
			end
		end
		
		class Interface
			def initialize(package)
				@package = package
			end

			def name(name)
				@package.name = name
			end
			
			def version(version)
				@package.version = version
			end
			
			def nodes(type = nil)
				@package.state.nodes(type)
			end
			
			def use(*args, &block)
				@package.state.use(@package.state.private, args, block)
			end
			
			def export(*args, &block)
				@package.state.use(@package.state.public, args, block)
			end
			
			def o(name, desc = nil)
			end
			
			def merge(nodes, using)
				@package.merge(nodes, using)
			end
			
			def platform
				Platform.new
			end
		end
		
		attr :name, true
		attr :version, true
		attr_reader :state
		
		def initialize(&block)
			@block = block
			@interface = Interface.new(self)
			@state = nil
		end
		
		def state_block(block)
			if block
				old_state = @state
				new_state = State.new(self, old_state)
				begin
					@state = new_state
					@interface.instance_eval(&block)
					yield
				ensure
					@state = old_state
				end
				new_state
			else
				yield
			end
		end
		
		def merge(nodes, target)
			mergers = target.mergers
			processor = nil
			if mergers
				merge_actions = []
				mergers.each do |merger|
					next unless @state.private.has_component?(merger, true)
					merge_action = merger.eval_merge(nodes, target)
					next unless merge_action
					merge_actions << merge_action
				end
				processor = merge_actions.find_all.min
			end
			
			raise "Unable to find a merger for #{target}." unless processor
			puts processor.inspect
		end
		
		def run
			state_block(@block) {}
		end
	end
end
