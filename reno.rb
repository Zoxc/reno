module Reno
	require 'rake'
	require 'rexml/document'
	
	ROOT = File.expand_path(File.dirname(__FILE__)) unless defined?(Reno::ROOT)
 
	unless $LOAD_PATH.any?{|lp| File.expand_path(lp) == ROOT }
		$LOAD_PATH.unshift(ROOT)
	end

	require 'reno/configuration'
	require 'reno/builder'
	require 'reno/cache'
	require 'reno/sourcefile'
	require 'reno/options'
	require 'reno/languages'
	require 'reno/compilers'
	require 'reno/package'
end