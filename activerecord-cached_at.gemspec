require File.expand_path("../lib/cached_at/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "activerecord-cached_at"
  spec.version       = CachedAt::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["Jon Bracy"]
  spec.email         = ["jonbracy@gmail.com"]
  spec.homepage      = "https://github.com/malomalo/activerecord-cached_at"
  spec.description   = %q{Allows ActiveRecord and Rails to use a `cached_at` column for the `cache_key` if available}
  spec.summary       = %q{Allows ActiveRecord and Rails to use a `cached_at` column for the `cache_key` if available}

  spec.extra_rdoc_files = %w(README.md)
  spec.rdoc_options.concat ['--main', 'README.md']

  spec.files         = `git ls-files -- README.md {lib,ext}/*`.split("\n")
  spec.test_files    = `git ls-files -- {test}/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activerecord', '>= 5.2.1'
    
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "byebug"
  # spec.add_development_dependency 'sdoc',                '~> 0.4'
  # spec.add_development_dependency 'sdoc-templates-42floors', '~> 0.3'
end
