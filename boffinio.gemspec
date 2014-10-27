# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'boffinio/version'

Gem::Specification.new do |spec|
  spec.name          = "boffinio"
  spec.version       = BoffinIO::VERSION
  spec.authors       = ["Tim Williams"]
  spec.email         = ["tim@teachmatic.com"]
  spec.summary       = %q{Gem wrapper for the Boffin.io API}
  spec.description   = %q{Gem wrapper for the Boffin.io API. Officially supported and maintained by the Boffin.io team }
  spec.homepage      = "http://www.boffin.io"
  spec.license       = "MIT"

  spec.files         =  `git ls-files`.split("\n")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"

  spec.add_dependency "rest-client"
  spec.add_dependency "json"
  spec.add_dependency('mime-types', '>= 1.25', '< 3.0')

end
