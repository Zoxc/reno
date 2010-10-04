module Reno
	module Arch
		class X86_64
			# MemoryModel is either :small, :kernel, :medium or :large
			MemoryModel = Option.new
			
			def self.name
				'x86_64'
			end
		end
	end
end
