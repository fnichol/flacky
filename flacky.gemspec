# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flacky/version'

Gem::Specification.new do |gem|
  gem.name          = "flacky"
  gem.version       = Flacky::VERSION
  gem.authors       = ["Fletcher Nichol"]
  gem.email         = ["fnichol@nichol.ca"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'nokogiri'
  gem.add_dependency 'flacinfo-rb'

  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'vcr'
  gem.add_development_dependency 'webmock', '~> 1.8.11'
  gem.add_development_dependency 'guard-minitest'
end
