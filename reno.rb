module Reno
	require 'rexml/document'
	
	ROOT = File.dirname(File.expand_path(__FILE__)) unless defined?(Reno::ROOT)
 
	unless $LOAD_PATH.any? { |lp| File.expand_path(lp) == ROOT }
		$LOAD_PATH.unshift(ROOT)
	end

	require 'reno/lock'
	require 'reno/configuration'
	require 'reno/builder'
	require 'reno/cache'
	require 'reno/platforms'
	require 'reno/sourcefile'
	require 'reno/options'
	require 'reno/languages'
	require 'reno/toolchains'
	require 'reno/package'
end