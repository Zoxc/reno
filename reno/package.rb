module Reno
	class Package
		class State
			attr_reader :public, :private
			
			def initialize(package, parent)
				@package = package
				@parent = parent
				@components = {}
				@public = Components.new
				@private = Components.new
			end
			
			def nodes(type = nil, private = true)
				(private ? @private : @public).nodes(type)
			end
			
			def use(components, args, block)
				result = []
				
				state = self
				
				if block
					state = @package.state_block(state, block)
				end
				
				args.each do |component|
					result.concat(components.use(component, state))
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
		end
		
		attr :name, true
		attr :version, true
		attr_reader :state
		
		def initialize(&block)
			@block = block
			@interface = Interface.new(self)
			@state = nil
		end
		
		def state_block(parent, block)
			old_state = @state
			new_state = State.new(self, old_state)
			begin
				@state = new_state
				@interface.instance_eval(&block)
			ensure
				@state = old_state
			end
			new_state
		end
		
		def run
			state_block(0, @block)
		end
	end
end
