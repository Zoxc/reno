module Reno
	class Lock
		def initialize(value = nil)
			@value = value
			@mutex = Mutex.new
		end
		
		def lock
			@mutex.synchronize do
				yield @value
			end
		end
		
		def value
			if block_given?
				@mutex.synchronize do
					return @value if @value
					@value = yield
				end
			else
				@mutex.synchronize do
					@value
				end
			end
		end
		
		def value=(value)
			@mutex.synchronize do
				@value = value
			end
		end
	end
end