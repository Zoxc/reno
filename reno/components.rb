module Reno
	class Components
		class ComponentsError < StandardError
		end
		
		attr_reader :owner
		
		def initialize(owner)
			@component_map = {}
			@owner = owner
		end
		
		def use(component)
			unless component.respond_to?(:use_component)
				components = [Conversions.convert(component, self)].flatten
			else
				components = [component]
			end
			
			components.map do |component|
				component.use_component(self)
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
				silent ? nil : raise(ComponentsError, "Unable to find component #{component.inspect}")
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
end