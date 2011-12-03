ENV["DATABASE_URL"] = "sqlite:/"
ENV["RACK_ENV"]     = "test"
ENV["REDIS_URL"]    = "redis://localhost:6379"

require "fakeweb"
require "rack/test"
require "./lib/code"

FakeWeb.allow_net_connect = false
Sequel.extension :migration

RSpec::Matchers.define :include_hash do |expected|
  match do |actual|
    actual.select { |k,v| expected.keys.include? k } == expected
  end
end