ENV["DATABASE_URL"] = "sqlite:/"
ENV["RACK_ENV"]     = "test"
ENV["REDIS_URL"]    = "redis://localhost:6379"

require "fakeweb"
require "rack/test"
require "./lib/code"

FakeWeb.allow_net_connect = false
Sequel.extension :migration