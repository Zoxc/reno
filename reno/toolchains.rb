module Reno
	module Toolchain
		Architecture = Option.new
		
		# Optimization is either :none, :speed, :balanced or :size
		Optimization = Option.new
		
		# Exceptions is either :none, :simple, :seh, :sjlj or :dwarf
		Exceptions = Option.new
		
		MergeConstants = BooleanOption.new
	end
end

require 'reno/toolchain/gnu'
require 'reno/toolchain/llvm'
