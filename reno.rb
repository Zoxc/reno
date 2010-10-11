require 'faster_require'
require 'digest/sha2'
require 'fileutils'
require 'sequel'
require 'pathname'

module Reno
	ROOT = File.dirname(File.expand_path(__FILE__)) unless defined?(Reno::ROOT)

	unless $LOAD_PATH.any? { |lp| File.expand_path(lp) == ROOT }
		$LOAD_PATH.unshift(ROOT)
	end
	
	require 'reno/dispatcher'
	require 'reno/interface'
	require 'reno/builder'
	require 'reno/digest'
	require 'reno/options'
	require 'reno/state'
	require 'reno/collection'
	require 'reno/cache'
	require 'reno/node'
	require 'reno/processor'
	require 'reno/file'
	require 'reno/package'
	require 'reno/objectfiles'
	require 'reno/languages'
	require 'reno/archs'
	require 'reno/toolchains'
end