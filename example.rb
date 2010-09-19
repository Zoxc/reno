require_relative 'reno'

include Reno

Package.new do
	name 'libc'
	publish 'msvcrt.dll'
end

Package.new do
	# name and version
	name 'library'
	version '0.2'
	use Toolchain::GNU
	
	# dependencies
	#use 'libc' => Package
	
	# languages
	c = use Languages::C
	c.std 'c99'

	# options
	#use platform.optimizer unless o('debug') { c.define 'DEBUG' }

	# files
	files = collect('**/*.c') { c.define 'c_files_only' => 'cool' }
	
	#files.merge(SharedLibrary)
	#export Languages::C::Headers => 'include'
	files.convert(ObjectFile)
end.run