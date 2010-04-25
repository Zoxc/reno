module Reno
	class Node
		include Stackable
		
		attr_reader :state
		
		def initialize(state)
			@state = state
		end
	end
end