module Reno
	module Languages
		class LanguageError < StandardError
		end
		
		def self.locate(name)
			Languages.constants.map { |lang| Languages.const_get(lang) }.each do |language|
				next unless Languages.is_language(language)
				
				if language.name == name
					return language
				end
			end
			
			raise "Unable to find the language '#{name}'."
		end
		
		def self.is_language(language)
			while language
				language = language.superclass
				return true if language == Languages::Language
			end
			nil
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
			
			def read(name)
				instance_variable_get "@#{name}"
			end
			
			class << self
				attr :name, true
				
				def priority
					0
				end
				
				def table_name(name, object = self)
					"lang_#{object.name}_#{name}".downcase.to_sym
				end
				
				def setup_table(cache, name, object = self, &block)
					cache.setup_table(table_name(name, object), &block)
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