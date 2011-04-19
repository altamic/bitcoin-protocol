# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "bitcoin-protocol"
  s.version     = Bitcoin::Protocol::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Michelangelo Altamore"]
  s.email       = ["michelangelo@altamore.org"]
  s.homepage    = ""
  s.summary     = %q{A Bitcoin wire protocol implementation in pure Ruby}
  s.description = %q{}
  s.rubyforge_project = "bitcoin-protocol"

  s.add_development_dependency('rake', [">= 0.8.7"])
  s.add_development_dependency('minitest', [">= 2.0.0"])

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

