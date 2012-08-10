# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.name    = "active_rest"
  s.version = version
  # NOTE: Many folks have contributed over the years; if you have participated
  # on the project and would like to be listed here, let me know!
  s.authors = ["anonymous"]
  s.summary = "A simple ORM for ST9"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "minitest"
  s.add_development_dependency "rake"
  
  s.add_runtime_dependency "activemodel", "~> 3.2.0"
  s.add_runtime_dependency "orm_adapter", "~> 0.0.5"
  s.add_runtime_dependency "silly_putty", "~> 0.1.0"
  s.add_runtime_dependency "json", "~> 1.0"
  s.add_runtime_dependency "tzinfo", "~> 0.3.29"
  s.add_runtime_dependency "activesupport", "~> 3.2.0"
  s.add_runtime_dependency "ffi", "= 1.0.9"
  s.add_runtime_dependency "escape"
end
