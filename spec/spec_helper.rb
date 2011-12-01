ENV["DATABASE_URL"] = "sqlite:/"
ENV["RACK_ENV"]     = "test"
ENV["REDIS_URL"]    = "redis://localhost:6379"

require "rack/test"
require "./lib/code"