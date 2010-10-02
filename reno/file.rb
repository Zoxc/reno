module Reno
	class File < Node
		Extension = HashOption.new
		
		class CreationError < StandardError
		end
		
		class << self
			attr_reader :dependency_generator
			
			def register(type, *args)
				case type
					when :ext
						ext = args[0]
						@ext = ext
					when :dependency_generator
						generator = args[0]
						@dependency_generator = generator
				end
			end
			
			def ext(dot = true)
				dot ? (@ext ? ".#{@ext}" : "") : @ext 
			end
			
			def collect(collect)
				@collect = collect
			end
			
			def collect?
				!(@collect == false)
			end
			
			def dependency_generator
				@dependency_generator
			end
			
			def use_component(package)
				package.state.set_option File::Extension, {@ext => self} if @ext
				nil
			end
		end
		
		attr_reader :filename, :origin, :id
		
		def initialize(filename, state)
			@filename = filename
			super(state)
		end
		
		def set_origin(digest, origin)
			@digest = digest
			@origin = origin
			self
		end
		
		def set_source(id)
			@id = id
			@origin = @filename
			self
		end
		
		def copy(path)
			Builder.readypath(path)
			FileUtils.copy(@filename, path)
			@state.package.cache.file_by_path(path, @state, nil, self.class).set_origin(@digest, @origin)
		end
		
		def relative(path)
			::File.expand_path(path, ::File.dirname(@filename))
		end
		
		def invalidate_dependencies
			@dependencies = nil
		end
		
		def dependencies
			@dependencies ||= begin
				raise "Circular dependencies" if @lock
				@lock = true
				dependencies = @state.package.cache.cache_dependencies(self) do
					generator = self.class.dependency_generator
					generator ? generator.find_dependencies(self) : []
				end
				@lock = nil
				dependencies
			end
		end
		
		def digest(path = [])
			return @digest if @digest
			
			@digest = @state.package.cache.cache_changes(self, path)
			path = path.dup << self
			dependencies.each do |dependency|
				@digest.update dependency.digest(path)
			end
			
			@digest.update self
		end
		
		def inspect
			"#<#{self.class} filename=#{@filename.inspect}>"
		end
	end
end