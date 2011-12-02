require "./spec/spec_helper"

describe "Code::Web::Director" do
  include Rack::Test::Methods
  include Code::Web::Helpers

  before do
    @ex = mock("exchange")
    Code::Exchange.stub!(:new).and_return(@ex)
  end

  def app
    Rack::Builder.new do
      map("/") { run Code::Web::Director }
    end
  end

  it "requests info for a repo and redirects to a backend" do
    @ex.should_receive(:hostname).and_return("code.heroku.com")
    @ex.should_receive(:exchange).with("backend.cedar", hash_including(app_name: "code-staging"), {:name => "code-staging"}).and_return(hostname: "route.heroku.com:3333")

    get "/code-staging.git/info/refs"
    last_response.status.should == 302
    last_response.location.should == "http://route.heroku.com:3333/code-staging.git/info/refs"
  end

  it "posts a pack to a repo and redirects to a backend" do
    @ex.should_receive(:get).with("code-staging").and_return(hostname: "route.heroku.com:3333")

    post "/code-staging.git/git-receive-pack"
    last_response.status.should == 302
    last_response.location.should == "http://route.heroku.com:3333/code-staging.git/git-receive-pack"
  end
end