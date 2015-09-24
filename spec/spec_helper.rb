require "bundler/setup"
require 'simplecov'
require 'coveralls'
Coveralls.wear!
SimpleCov.start
require "rspec"
require "rack/test"
require "webmock/rspec"
require "omniauth"
require "omniauth-marvin"

RSpec.configure do |config|

  config.include WebMock::API
  config.include Rack::Test::Methods
  config.extend OmniAuth::Test::StrategyMacros, type: :strategy
end
