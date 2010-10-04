module Reno
	module Arch
		RedZone = BooleanOption.new
		FreeStanding = BooleanOption.new
	end
end

require 'reno/archs/x86'
require 'reno/archs/x86_64'