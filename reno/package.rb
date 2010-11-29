module Reno
	class Package
		class Interface < Reno::Interface
			def name(name = nil)
				name ? package.name = name : package.name
			end
			
			def version(version)
				package.version = version
			end
			
			def nodes(type = nil)
				package.state.nodes(type)
			end
			
			def set(option, value)
				package.state.set_option option, value
			end
			
			def collect(*patterns, &block)
				collection = Collection.new(package)
				
				package.state_block(block) do
					collection.collect(*patterns)
				end
				
				collection
			end
			
			def use(*args, &block)
				package.state.use(args, block)
			end
			
			def o(name, desc = nil)
			end
		end
		
		attr :name, true
		attr :version, true
		attr_reader :state, :cache
		
		def initialize(&block)
			@block = block
			@interface = Interface.new(self)
			@state = nil
		end
		
		def cache_collection(nodes, target, option_set = nil, &block)
			@cache.cache_collection(self, nodes, target, option_set, &block)
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
		
		def measure(&block)
			start = Time.now
			block.call
			stop = Time.now
			stop - start;
		end
		
		def generate(&block)
			@generated += measure(&block);
		end
		
		def run
			@generated = 0
			time = measure do
				@cache = Cache.new('cache', Dir.pwd)
				@dispatcher = Dispatcher.new
				state_block(@block) {}
				@dispatcher = nil
				@cache.purge
			end
			puts "Processed %s in %.2fs, excluding generation %.2fs" % [@name, time, time - @generated]
		ensure
			@cache = nil
		end
	end
end
