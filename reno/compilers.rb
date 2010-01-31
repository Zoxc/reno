module Reno
	module Compilers
		class CompilerError < StandardError
		end
		
		@languages = {}
		
		def self.register(compiler, language)
			array = @languages[language]
			array = @languages[language] = [] unless array
			array << compiler
		end
		
		def self.locate(language)
			array = @languages[language]

			raise "Unable to find a compiler for the language '#{language}'." unless array
			
			array.first
		end
	
		class Compiler
			attr_reader :option
			
			def self.get_dependencies(file)
				file.language.get_dependencies(file)
			end
			
			def self.register(*languages)
				languages.each do |language|
					Compilers.register(self, language)
				end
			end
		end
	end
end