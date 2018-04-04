# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "much-timeout/version"

Gem::Specification.new do |gem|
  gem.name        = "much-timeout"
  gem.version     = MuchTimeout::VERSION
  gem.authors     = ["Kelly Redding", "Collin Redding"]
  gem.email       = ["kelly@kellyredding.com", "collin.redding@me.com"]
  gem.summary     = "IO.select based timeouts; an alternative to Ruby's stdlib Timeout module."
  gem.description = "IO.select based timeouts; an alternative to Ruby's stdlib Timeout module."
  gem.homepage    = "http://github.com/redding/much-timeout"
  gem.license     = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency("assert", ["~> 2.16.3"])

end
