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
		
		def apply_options(option_hash)
			@parent.apply_options(option_hash) if @parent
			
			option_hash.each_key do |option|
				if @options.has_key?(option)
					option_hash[option] = option.merge(option_hash[option], @options[option])
				end
			end
		end
		
		def map_options(option_set)
			option_hash = {}
			option_set.each do |option|
				option_hash[option] = option.default
			end
			apply_options(option_hash)
			OptionMap.new(option_hash)
		end
		
		def set_option(option, value)
			if @options.has_key?(option)
				@options[option] = option.merge(@options[option], value)
			else
				@options[option] = option.set(value)
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
