# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "exchange-offline-address-book"
  spec.version       = '0.0.1'
  spec.authors       = ["Emiliano Heyns"]
  spec.email         = ["Emiliano.Heyns@iris-advies.com"]
  spec.description   = %q{Get Exchange Offline Address Book}
  spec.summary       = %q{Get Exchange Offline Address Book}
  spec.homepage      = "http://github.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.3'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "dotenv", '~> 2'
  spec.add_development_dependency "minitest", '~> 5'
  spec.add_development_dependency "gem-release", '~> 1'
  spec.add_development_dependency "bump", '~> 0.5'

  spec.add_runtime_dependency 'nokogiri', '~> 1.8'
  spec.add_runtime_dependency 'autodiscover', '~> 1'
  spec.add_runtime_dependency 'libmspack', '~> 0.1'
  spec.add_runtime_dependency 'curb', '~> 0.9'
end
