module Reno
	class Assembly < File
		register :ext, 's'
	end
	
	class ObjectFile < File
		register :ext, 'o'
	end
	
	class Executable < ObjectFile
		register :ext, 'exe'
	end
	
	class Library < ObjectFile
	end
	
	class SharedLibrary < Library
		register :ext, 'dll'
	end
	
	class StaticLibrary < Library
		register :ext, 'obj'
	end
end
