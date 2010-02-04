module Reno
	module Languages
		class LanguageError < StandardError
		end
		
		def self.locate(name, default = nil, cache = nil)
			lang = name || default
			
			raise "Unable to find the default language." unless lang
			
			lang = lang.to_s
			
			return cache[lang] if cache && cache[lang]
			
			Languages.constants.map { |name| Languages.const_get(name) }.each do |language|

				next if language.superclass != Language
				
				if language.name == lang
					return language
				end
			end
			
			raise "Unable to find the language '#{lang}'."
		end
	
		class Language
			attr_reader :option
			
			def inspect
				"#<Language:#{self.class.name}>"
			end
			
			def initialize(option, block)
				@option = option
				instance_eval(&block) if block
			end
			
			def get_dependencies(file)
				[]
			end

			
			class << self
				attr :name, true
				
				def table_name(name)
					"lang_#{self.name}_#{name}".downcase.to_sym
				end
				
				def setup_table(cache, name, &block)
					cache.setup_table(table_name(name), &block)
				end
				
				def setup_schema(cache)
				end
				
				def merge(nodes)
					result = new(nil, nil)
					nodes.each { |node| result.merge(node) }
					result
				end
			end
		end
	end
end