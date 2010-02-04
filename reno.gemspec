Gem::Specification.new do |s|
	s.name = 'reno'
	s.version = '0.1.0'
	s.author = 'Zoxc'
	s.require_path = '.'
	s.required_ruby_version = '>= 1.9.0'
	s.summary = 'Reno is a compiling framework in Ruby.'
	s.files = ['LICENSE', 'reno.rb']
	s.files << Dir['reno/**/*']
end