require "./spec/spec_helper"

describe "Code::Web::Director" do
  include Rack::Test::Methods
  include Code::Web::Helpers

  before do
    @ex = mock("exchange")
    Code::Exchange.stub!(:new).and_return(@ex)

    metadata = {
      "env"               => {"BUILDPACK_URL" => "https://github.com/heroku/heroku-buildpack-ruby.git"},
      "heroku_log_token"  => "t.8d3d88ea-31e5-47e5-9fac-1748101d05bc",
      "id"                => 1905640,
      "repo_get_url"      => "http://s3-external-1.amazonaws.com/heroku_repos/staging.herokudev.com/1905640.tgz",
      "repo_put_url"      => "http://s3-external-1.amazonaws.com/heroku_repos/staging.herokudev.com/1905640.tgz",
      "release_url"       => "https://SECRET_KEY@api.staging.herokudev.com/apps/code/1905640",
      "slug_put_url"      => "http://s3-external-1.amazonaws.com/herokuslugs/staging.herokudev.com/HASH",
      "user_email"        => "noah@heroku.com",
      "stack"             => "cedar"
    }
    FakeWeb.register_uri(:get, "https://api.heroku.com/apps/code-staging/releases/new", :body => "Unauthorized", :status => ["401", "Unauthorized"])
    FakeWeb.register_uri(:get, "https://:API_TOKEN@api.heroku.com/apps/code-staging/releases/new", :body => JSON.dump(metadata), :status => ["200", "OK"])
  end

  def app
    Rack::Builder.new do
      map("/") { run Code::Web::Director }
    end
  end

  it "uses basic auth" do
    get "/code-staging.git/info/refs"
    last_response.status.should == 401
    last_response.headers.should include "WWW-Authenticate"
  end

  it "requests info for a repo and redirects to a backend" do
    authorize("", "API_TOKEN")

    @ex.should_receive(:hostname).and_return("code.heroku.com")
    @ex.should_receive(:exchange).with(
      "backend.cedar",
      hash_including(app_name: "code-staging"),
      {:name => "code-staging", timeout: 30}
    ).and_return(hostname: "route.heroku.com:3333")

    get "/code-staging.git/info/refs"
    last_response.status.should == 302
    last_response.location.should == "http://route.heroku.com:3333/code-staging.git/info/refs"
  end

  it "posts a pack to a repo and redirects to a backend" do
    authorize("", "API_TOKEN")

    @ex.should_receive(:get).with("code-staging").and_return(hostname: "route.heroku.com:3333")

    post "/code-staging.git/git-receive-pack"
    last_response.status.should == 302
    last_response.location.should == "http://route.heroku.com:3333/code-staging.git/git-receive-pack"
  end
end