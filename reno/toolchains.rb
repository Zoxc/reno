module Reno
	module Toolchain
		Architecture = Option.new
		
		# Optimization is either :none, :speed, :balanced or :size
		Optimization = Option.new
		
		FreeStanding = BooleanOption.new
	end
end

require 'reno/toolchain/gnu'
require 'reno/toolchain/llvm'
