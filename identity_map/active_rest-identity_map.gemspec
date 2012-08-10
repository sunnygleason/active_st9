# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.name        = 'active_rest-identity_map'
  s.version     = version
  # NOTE: Many folks have contributed over the years; if you have participated
  # on the project and would like to be listed here, let me know!
  s.authors     = ['anonymous']
  s.summary     = 'Identity map for ActiveRest'

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"

  s.add_runtime_dependency "active_rest", version

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map { |f| f =~ /^bin\/(.*)/ ? $1 : nil }.compact
  s.require_path = 'lib'
end
