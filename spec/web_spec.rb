require "rack/test"
require "./lib/code"

set :environment, :test

describe Code::Web do
  include Rack::Test::Methods
  include Code::Helpers

  before do
    @ex = exchange
    @ex.redis.flushdb
  end

  def app
    Rack::Builder.new do
      map("/") { run Code::Web }
    end
  end

  it "requests info for a repo and redirects to a backend" do
    get "/code.git/info/refs"
    last_response.status.should == 302
    last_response.location.should == "https://route.heroku.com:3333/code.git/info/refs"
  end

  it "posts a pack to a repo and redirects to a backend" do
    post "/code.git/git-receive-pack?foo=bar"
    last_response.status.should == 302
    last_response.location.should == "https://route.heroku.com:3333/code.git/git-receive-pack"
  end
end