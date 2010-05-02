module Reno
	class Package
		class State
			class StateComponentError < StandardError
			end
			
			def initialize(package, parent)
				@package = package
				@parent = parent
				@component_map = {}
			end
			
			def use(component, settings)
				unless component.respond_to?(:use_component)
					components = [Conversions.convert(component, self, settings)].flatten
				else
					components = [component]
				end
				
				components.map do |component|
					component.use_component(self, settings)
				end
			end
			
			def set_component(component, value)
				@component_map[component] = value
			end
			
			def get_component(component, silent = false)
				if @component_map.has_key?(component)
					@component_map[component]
				elsif @parent
					@parent.get_component(component, silent)
				else
					silent ? nil : raise(StateComponentError, "Unable to find component #{component.inspect}")
				end
			end
			
			def has_component?(component, recursive = true)
				if @component_map.has_key?(component)
					true
				elsif @parent && recursive
					@parent.has_component?(component)
				else
					false
				end
			end
			
			def nodes(type = nil)
				if has_component?(Node)
					nodes = get_component(Node)
					if type
						nodes.reject! { |node| !(node.class <= type) }
					end
					nodes
				else
					[]
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
				result = []
				
				state = @state
				
				if block
					state = @package.state(state, block)
				end
				
				args.each do |component|
					result.concat(@state.use(component, state))
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
			
			def export(*args)
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
			new_state = State.new(@package, old_state)
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