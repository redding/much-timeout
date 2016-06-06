# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "much-timeout/version"

Gem::Specification.new do |gem|
  gem.name        = "much-timeout"
  gem.version     = MuchTimeout::VERSION
  gem.authors     = ["TODO: authors"]
  gem.email       = ["TODO: emails"]
  gem.summary     = "TODO: Write a gem summary"
  gem.description = "TODO: Write a gem description"
  gem.homepage    = "TODO: homepage"
  gem.license     = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency("assert", ["~> 2.16.1"])
  # TODO: gem.add_dependency("gem-name", ["~> 0.0.0"])

end
