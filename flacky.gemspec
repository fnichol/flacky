# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flacky/version'

Gem::Specification.new do |gem|
  gem.name          = "flacky"
  gem.version       = Flacky::VERSION
  gem.authors       = ["Fletcher Nichol"]
  gem.email         = ["fnichol@nichol.ca"]
  gem.summary       = %q{Loose collection of CLI commands to sort and process Flac files}
  gem.description   = gem.summary
  gem.homepage      = "https://github.com/fnichol/flacky"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'thor'
  gem.add_dependency 'nokogiri'
  gem.add_dependency 'flacinfo-rb'

  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'vcr'
  gem.add_development_dependency 'webmock', '~> 1.8.11'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'guard-minitest'
end
