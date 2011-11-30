require "./spec/spec_helper"

describe Code::Web do
  include Rack::Test::Methods
  include Code::Helpers

  before do
    @ex = mock("exchange")
    Code::Exchange.stub!(:new).and_return(@ex)
  end

  def app
    Rack::Builder.new do
      map("/") { run Code::Web }
    end
  end

  it "requests info for a repo and redirects to a backend" do
    @ex.should_receive(:exchange).with("backend.cedar", {:app_name => "code"}, {:name => "code"}).and_return(hostname: "route.heroku.com:3333")

    get "/code.git/info/refs"
    last_response.status.should == 302
    last_response.location.should == "http://route.heroku.com:3333/code.git/info/refs"
  end

  it "posts a pack to a repo and redirects to a backend" do
    @ex.should_receive(:get).with("code").and_return(hostname: "route.heroku.com:3333")

    post "/code.git/git-receive-pack"
    last_response.status.should == 302
    last_response.location.should == "http://route.heroku.com:3333/code.git/git-receive-pack"
  end
end