Gem::Specification.new do |s|
  s.name        = "cenit_cmd"
  s.version     = "0.0.4"
  s.authors     = ["Miguel Sancho"]
  s.email       = ["sanchojaf@gmail.com"]
  s.homepage    = "https://github.com/openjaf/cenit_cmd"
  s.license     = %q{MIT}
  s.summary     = %q{Cenit Hub command line utility}
  s.description = %q{tools to create new collections}

  s.rubyforge_project = "cenit_cmd"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_dependency 'thor', '~> 0.14'
end
