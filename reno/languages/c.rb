module Reno
	module Languages
		class C < Language
			Standard = Option.new
			Defines = HashOption.new
			
			class Preprocessor
				# The find_dependencies method is under the GNU LESSER GENERAL PUBLIC LICENSE - Version 2.1, February 1999 license.
				# It's from rant-0.5.8\lib\rant\c\include.rb
				
				# include.rb - Support for C - parsing #include statements.
				#
				# Copyright (C) 2005 Stefan Lang <langstefan@gmx.at>

				# Modified by Zoxc
				
				# Searches for all `#include' statements in the C/C++ source
				# from the string +src+.
				#
				# Returns two arguments:
				# 1. A list of all local includes (e.g. #include "stdio.h").
				
				def self.find_dependencies(file)
					src = ::File.open(file.filename, 'r') { |file| file.read }
					
					includes = []
					in_block_comment = false
					prev_line = nil
					
					src.each_line do |line|
						line.chomp!
						
						if block_start_i = line.index("/*")
							c_start_i = line.index("//")
							if !c_start_i || block_start_i < c_start_i
								if block_end_i = line.index("*/")
									if block_end_i > block_start_i
										line[block_start_i..block_end_i+1] = ""
									end
								end
							end
						end
						
						if prev_line
							line = prev_line << line
							prev_line = nil
						end
						
						if line =~ /\\$/
							prev_line = line.chomp[0...line.length-1]
						end
						
						if in_block_comment
							in_block_comment = false if line =~ %r|\*/|
							next
						end
						
						case line
							when /\s*#\s*include\s+"([^"]+)"/
								includes << [file.relative($1), file.class]
							when %r|(?!//)[^/]*/\*|
								in_block_comment = true
						end
					end
					
					includes
				end
			end
			
			class Interface < Reno::Interface
				def std(std)
					state.set_option Standard, std
				end
				
				def define(name, value = nil)
					state.set_option Defines, {name => value}
				end
			end
			
			class File < Reno::File
				register :dependency_generator, Preprocessor
			end
			
			class HeaderFile < Reno::File
				register :dependency_generator, Preprocessor
				collect false
			end
			
			register :interface, Interface
			register :ext, 'c', File
			register :ext, 'h', HeaderFile
		end
	end
	
	class Assembly < File
		class WithCPP < File
			register :ext, 'S'
			register :dependency_generator, Languages::C::Preprocessor
		end
	end
end