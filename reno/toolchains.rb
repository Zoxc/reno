module Reno
	module Toolchain
		Architecture = Option.new
		
		# Optimization is either :none, :speed, :balanced or :size
		Optimization = Option.new
		
		# Exceptions is either :none, :simple, :seh, :sjlj or :dwarf
		Exceptions = Option.new
		
		Reflection = BooleanOption.new
		
		# StackProtection is either :none, :partial or :full
		StackProtection = Option.new
		
		MergeConstants = BooleanOption.new
		
		Libraries = ListOption.new
		
		StaticLibraries = BooleanOption.new
		
		DebugInformation = BooleanOption.new
	end
end

require 'reno/toolchain/gnu'
require 'reno/toolchain/llvm'
