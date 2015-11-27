# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/marvin/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-marvin"
  spec.version       = Omniauth::Marvin::VERSION
  spec.authors       = ["Samy KACIMI"]
  spec.email         = ["samy.kacimi@gmail.com"]

  spec.summary       = %q{OmniAuth OAuth2 strategy for 42 School}
  spec.description   = %q{This gem is an OmniAuth OAuth2 strategy for 42 School. 42 Students can use it to signup/login on their apps.}
  spec.homepage      = "https://github.com/fakenine/omniauth-marvin"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'omniauth-oauth2', '1.3.1'
  spec.add_runtime_dependency 'multi_json', '~> 1.3'

  spec.add_development_dependency "bundler", "~> 1.10"
end
