module Reno
	module Toolchains
		class ToolchainError < StandardError
		end
		
		Hash = {}
		Compilers = {}
		
		def self.register(toolchain, language)
			array = Compilers[language]
			array = Compilers[language] = [] unless array
			array << toolchain
		end
		
		def self.locate(language)
			array = Compilers[language.name]

			raise "Unable to find a compiler for the language '#{language.name}'." unless array
			
			array.first
		end
	
		class Toolchain
			attr_reader :option
			
			def self.get_dependencies(file)
				file.language.get_dependencies(file)
			end
			
			def self.register(name, *languages)
				Hash[name] = self
				
				languages.each do |language|
					Toolchains.register(self, language)
				end
			end
		end
	end
end