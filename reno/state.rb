module Reno	
	class Option
		def new(value)
			value
		end
		
		def merge(low, high)
			high
		end
	end

	class State
		attr_reader :package
		
		def initialize(package, parent)
			@package = package
			@parent = parent
			@options = {}
			@nodes = {}
		end
		
		def get_processor(processor)
			@nodes[processor] || (@parent && @parent.get_processor(processor))
		end
		
		def set_processor(processor, enabled)
			@nodes[processor] = enabled
		end
		
		def has_option?(option)
			@options.has_key?(option) || @parent.has_option(option)
		end
		
		def get_option(option)
			if @options.has_key?(option)
				@options[option]
			elsif @parent
				@parent.get_option(option)
			else
				option.default
			end
		end
		
		def set_option(option, value)
			if @options.has_key?(option)
				@options[option] = option.merge(@options[option], value)
			else
				@options[option] = value
			end
		end
		
		def use(args, block)
			result = []
			
			@package.state_block(block) do
				args.each do |component|
					result << component.use_component(@package)
				end
			end
			
			if result.empty?
				nil
			elsif result.size == 1
				result.first
			else
				result
			end
		end
	end
end
