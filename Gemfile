source 'https://rubygems.org'

# Specify your gem's dependencies in flacky.gemspec
gemspec

group :test do
  gem 'rake', '~> 10.0'
end

require 'rbconfig'

if RbConfig::CONFIG['target_os'] =~ /darwin/i
  gem 'rb-fsevent', '>= 0.3.9'
  gem 'growl',      '~> 1.0.3'
end
if RbConfig::CONFIG['target_os'] =~ /linux/i
  gem 'rb-inotify', '>= 0.5.1'
  gem 'libnotify',  '~> 0.1.3'
end
