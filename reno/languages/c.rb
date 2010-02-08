module Reno
	module Languages
		class C < Language
			self.name = 'C'
			
			def initialize(*args)
				@defines = {}
				@headers = []
				@std = nil
				@strict = nil
				super
			end
			
			def compare(file)
				defines = file.db[self.class.table_name(:defines)]
				attribs = file.db[self.class.table_name(:attribs)]
				
				hash = {}
				
				defines.filter(:file => file.row[:id]).all do |row|
					hash[row[:define]] = row[:value]
				end
				
				attribs = attribs.filter(:file => file.row[:id]).first
				attribs = {:std => nil, :strict => false} unless attribs
				
				hash == @defines and attribs[:std] == @std.to_s and attribs[:strict] == @strict
			end
			
			def print(*values)
				puts values.inspect
			end
			
			def store(file)
				defines = file.db[self.class.table_name(:defines)]
				attribs = file.db[self.class.table_name(:attribs)]
				
				# Delete existing rows				
				defines.filter(:file => file.row[:id]).delete
				attribs.filter(:file => file.row[:id]).delete
				
				# Add the current ones
				@defines.each_pair do |key, value|
					defines.insert(:file => file.row[:id], :define => key, :value => value)
				end
				
				attribs.insert(:file => file.row[:id], :strict => @strict, :std => @std.to_s)
			end
			
			def self.setup_schema(cache)
				setup_table(cache, :defines) do
					Integer :file
					String :define
					String :value
				end
				
				setup_table(cache, :attribs) do
					Integer :file
					FalseClass :strict
					String :std
				end
			end
			
			def merge(other)
				@defines.merge!(other.read(:defines))
				
				other_value = other.read(:std)
				@std = other_value if other_value
				
				other_value = other.read(:strict)
				@strict = other_value if other_value != nil
				
				@headers.concat(other.read(:headers))
			end
			
			def define(name, value = nil)
				@defines[name] = value
			end
			
			def strict(value = true)
				@strict = value
			end
			
			def std(value)
				@std = value
			end
			
			def self.extract_headers(language, dependencies)
				headers = []
				dependencies.each do |dependency|
					langs = dependency.conf.get(:langs, nil).map { |langs| langs[language.name] }.reject { |lang| !lang }
					puts language.merge(langs).read(:headers).inspect
					language.merge(langs).read(:headers).each do |header|
						headers << File.expand_path(header, dependency.package.base)
						puts File.expand_path(header, dependency.package.base).inspect
					end
				end
				headers
			end
			
			def headers(*dirs)
				@headers.concat(dirs)
			end
			
			def self.extensions
				['.c', '.h']
			end
			
			# The get_dependencies method is under the GNU LESSER GENERAL PUBLIC LICENSE - Version 2.1, February 1999 license.
			# It's from rant-0.5.8\lib\rant\c\include.rb
			
			# include.rb - Support for C - parsing #include statements.
			#
			# Copyright (C) 2005 Stefan Lang <langstefan@gmx.at>

			
			# Searches for all `#include' statements in the C/C++ source
			# from the string +src+.
			#
			# Returns two arguments:
			# 1. A list of all standard library includes (e.g. #include <stdio.h>).
			# 2. A list of all local includes (e.g. #include "stdio.h").
			
			def self.get_dependencies(file)
				src = file.content

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
							includes << $1
						when %r|(?!//)[^/]*/\*|
							in_block_comment = true
					end
				end
				
				includes
			end
		end
	end
end