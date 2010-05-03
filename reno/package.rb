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
			
			def use(compoonents, args, block)
				result = []
				
				state = self
				
				if block
					state = @package.state(state, block)
				end
				
				args.each do |component|
					result.concat(compoonents.use(component, state))
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
			attr :state, true
			
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
				@state.nodes(type)
			end
			
			def use(*args, &block)
				@state.use(@state.private, args, block)
			end
			
			def export(*args, &block)
				@state.use(@state.public, args, block)
			end
			
			def o(name, desc = nil)
			end
		end
		
		attr :name, true
		attr :version, true
		
		def initialize(&block)
			@block = block
			@interface = Interface.new(self)
			@state = nil
		end
		
		def state(parent, block)
			old_state = @interface.state
			new_state = State.new(self, old_state)
			begin
				@interface.state = new_state
				@interface.instance_eval(&block)
			ensure
				@interface.state = old_state
			end
			new_state
		end
		
		def run
			state(0, @block)
		end
	end
end