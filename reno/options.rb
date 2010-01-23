module Reno
	class Options
		def initialize(conf, data, block)
			@conf = conf
			@data = []
			eval(data, block)
		end
		
		def o(symbol, desc, default = false, &block)
			node = find_node(symbol.to_s)
			attribute = node && node.attribute('value')
			value = attribute ? attribute.value : default
			
			eval(node, block) if value == 'true'
		end
		
		def group(symbol, desc = nil, &block)
			node = find_node(symbol.to_s)
			eval(node, block)
		end

		def lang(name)
			@conf.language(name)
		end
		

		def file(name)
			@conf.file(name)
		end
		
		alias :files :file
		
		private
			def find_node(name)
				@data.last.elements.find { |element| element.attribute('name').value == name }
			end
			
			def eval(data, block)
				return unless block
				@data.push(data)
				instance_eval(&block)
				@data.pop
			end
	end
end