module Reno
	module Languages
		class LanguageError < StandardError
		end
		
		def self.locate(name, default = nil, cache = nil)
			lang = name || default
			
			raise "Unable to find the default language!" unless lang
			
			lang = lang.to_s
			
			return cache[lang] if cache && cache[lang]
			
			raise "Unable to find language #{lang}!" unless Languages.const_defined?(lang)
			
			Languages.const_get(lang)
		end
	
		class Language
			attr_reader :option
			
			def initialize(option, block)
				@option = option
				instance_eval(&block) if block
			end
		end
	end
end