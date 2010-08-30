module Reno
	class ObjectFile < File
	end
	
	class Executable < ObjectFile
	end
	
	class Library < ObjectFile
	end
	
	class SharedLibrary < Library
	end
	
	class StaticLibrary < Library
	end
end
