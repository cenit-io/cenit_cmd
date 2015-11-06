# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cenit_cmd/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = "cenit_cmd"
  s.version     = CenitCmd::VERSION
  s.authors     = ['Miguel Sancho','Asnioby Hernandez', 'Maikel Arcia']
  s.email       = ['sanchojaf@gmail.com','asnioby@gmail.com', 'macarci@gmail.com']
  s.homepage    = "https://github.com/openjaf/cenit_cmd"
  s.license     = %q{MIT}
  s.summary     = %q{Cenit Hub command line utility}
  s.description = %q{tools to create new collections}
  s.required_ruby_version = '>= 2.0.0'

  s.rubyforge_project = "cenit_cmd"

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.9"
  s.add_development_dependency "rake", "~> 10.0"

  s.add_dependency 'thor', '~> 0.14'
end

