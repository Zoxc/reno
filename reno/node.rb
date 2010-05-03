module Reno
	class Node
		class Link
			attr_reader :processor
			attr_reader :node
			
			def initialize(processor, node)
				@processor = processor
				@node = processor
			end
		end
		
		def initialize
			@map = {}
		end
		
		def link(processor, output)
			if @map.has_key?(output)
				@map[output] << Link.new(processor, output)	
			else
				@map[output] = [Link.new(processor, output)]
			end
		end
	end
end