module Reno
	ROOT = File.expand_path(File.dirname(__FILE__)) unless defined?(Reno::ROOT)
 
	unless $LOAD_PATH.any?{|lp| File.expand_path(lp) == ROOT }
		$LOAD_PATH.unshift(ROOT)
	end
	
	require 'rake'
	require 'rexml/document'
	require 'reno/options'
	require 'reno/langs'
	require 'reno/toolchains'
	require 'reno/package'
end