require "rack/test"
require "./lib/code"

set :environment, :test

describe Code::Web do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      map("/") { run Code::Web }
    end
  end

  it "requests info for a repo and redirects to a backend" do
    get "/code.git/info/refs"
    last_response.status.should == 302
  end

  it "posts a pack to a repo and redirects to a backend" do
    post "/code.git/git-receive-pack"
    last_response.status.should == 302
  end
end