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

def metadata(opts={})
  opts.reverse_merge! heroku_host: "heroku.com", stack: "cedar"
  {
      "env"               => {},
      "heroku_log_token"  => "t.8d3d88ea-31e5-47e5-9fac-1748101d05bc",
      "id"                => 1905640,
      "repo_get_url"      => "http://s3-external-1.amazonaws.com/heroku_repos/#{opts[:heroku_host]}/1905640.tgz",
      "repo_put_url"      => "http://s3-external-1.amazonaws.com/heroku_repos/#{opts[:heroku_host]}/1905640.tgz",
      "release_url"       => "https://SECRET_KEY@api.#{opts[:heroku_host]}/apps/code/1905640",
      "slug_put_url"      => "http://s3-external-1.amazonaws.com/herokuslugs/#{opts[:heroku_host]}/HASH",
      "user_email"        => "noah@heroku.com",
      "stack"             => opts[:stack],
      "url"               => "code-staging.herokuapp.com"
    }
end