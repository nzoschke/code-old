require "rack/test"
require "./lib/code"

set :environment, :test

describe Code::Web do
  include Rack::Test::Methods
  def app
    Code::Web
  end

  it "says hello" do
    get "/"
    last_response.status.should == 200
    last_response.body.should == "hello world"
  end
end