# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require '<%= file_name %>/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = '<%= file_name %>'
  s.version     =  <%= class_name %>::VERSION
  s.summary     = 'TODO: Add gem summary here'
  s.description = 'TODO: Add (optional) gem description here'
  s.required_ruby_version = '>= 2.0.0'

  # s.author    = 'You'
  # s.email     = 'you@example.com'
  # s.homepage  = 'http://www.cenitsaas.com'

  #s.files       = `git ls-files`.split("\n")
  # s.bindir        = "exe"
  # s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'json'
  s.add_development_dependency 'collection_base'
  s.add_development_dependency 'cenithub-client'

  gem 'json'
  s.require_path = 'lib'
  s.requirements << 'none'
end
