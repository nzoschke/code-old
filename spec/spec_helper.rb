ENV["DATABASE_URL"] = "sqlite:/"
ENV["RACK_ENV"]     = "test"
ENV["REDIS_URL"]    = "redis://localhost:6379"

require "bundler"
Bundler.setup

require "fakeweb"
require "rack/test"
require "./lib/code"

FakeWeb.allow_net_connect = false
Sequel.extension :migration

RSpec.configure do |config|
  config.before(:each) { Sequel::Migrator.apply(Sequel::DATABASES[0], "db/migrations") }
  config.after(:each)  { Sequel::DATABASES[0].disconnect }
end

RSpec::Matchers.define :include_hash do |expected|
  match do |actual|
    actual.select { |k,v| expected.keys.include? k } == expected
  end
end