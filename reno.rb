module Reno
	ROOT = File.dirname(File.expand_path(__FILE__)) unless defined?(Reno::ROOT)
 
	unless $LOAD_PATH.any? { |lp| File.expand_path(lp) == ROOT }
		$LOAD_PATH.unshift(ROOT)
	end

	require 'reno/conversions'
	require 'reno/stackable'
	require 'reno/mergable'
	require 'reno/node'
	require 'reno/file'
	require 'reno/package'
	require 'reno/languages'
end