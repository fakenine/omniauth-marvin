require "bundler/setup"
require 'simplecov'
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
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
