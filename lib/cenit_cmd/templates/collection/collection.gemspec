# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cenit/collection/<%= collection_name %>/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = '<%= file_name %>'
  s.version     =  Cenit::Collection::<%= class_name %>::VERSION
  s.summary     = '<%= summary %>'
  s.description = '<%= description %>'
  s.required_ruby_version = '>= 2.0.0'

  s.author    = '<%= user_name %>'
  s.email     = '<%= user_email %>'
  s.homepage  = '<%= homepage %>'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.9"
  s.add_development_dependency "rake", "~> 10.0"
  s.requirements << 'none'
end
