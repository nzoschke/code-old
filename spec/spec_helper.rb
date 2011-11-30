require "rack/test"
require "./lib/code"

ENV["REDIS_URL"] = "redis://localhost:6379"
set :environment, :test