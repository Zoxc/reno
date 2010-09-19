module Reno
	class Interface
		attr_reader :package
		
		def initialize(package)
			@package = package
		end

		def state
			@package.state
		end
	end
end
