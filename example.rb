require 'reno'

Reno::Package.new do
	name 'libc'
	publish 'msvcrt.dll'
end

Reno::Package.new do
	# name and version
	name 'library'
	version '0.2'
	
	# dependencies
	#use 'libc' => Package
	
	# languages
	c = use Languages::C
	c.std 'c99'

	# options
	#use platform.optimizer unless o('debug') { c.define 'DEBUG' }

	# files
	use('**/*.c') { c.define 'c_files_only' => 'cool' }
	use '**/*.yy', '**/*.asm'

	#export Languages::C::Headers => 'include'
	#export merge(platform.library)
end.run