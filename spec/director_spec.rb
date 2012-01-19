require "./spec/spec_helper"

describe "Code::Web::Director" do
  include Code::Web::Helpers

  before do
    @logs = []
    Log.stub!(:write).and_return { |log| @logs << log }
    
    @ex = mock("exchange")
    Code::Exchange.stub!(:new).and_return(@ex)

    FakeWeb.register_uri(:get, "https://api.heroku.com/apps/code-staging/releases/new", :body => "Unauthorized", :status => ["401", "Unauthorized"])
    FakeWeb.register_uri(:get, "https://:API_TOKEN@api.heroku.com/apps/code-staging/releases/new", :body => JSON.dump(metadata), :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "https://:API_TOKEN@api.staging.herokudev.com/apps/code-staging/releases/new", :body => JSON.dump(metadata(heroku_host: "staging.herokudev.com")), :status => ["200", "OK"])

    FakeWeb.register_uri(:get, "https://:API_TOKEN@api.heroku.com/apps/code-staging", :body => JSON.dump({}), :status => ["200", "OK"])
  end

  def app
    Rack::Builder.new do
      map("/") { run Code::Web::Director }
    end
  end

  def session(host="code.heroku.com")
    @session ||= Rack::Test::Session.new(Rack::MockSession.new(app, host))
  end

  it "uses basic auth" do
    session.get "/code-staging.git/info/refs"
    session.last_response.status.should == 401
    session.last_response.headers.should include "WWW-Authenticate"
  end

  it "requests info for a repo and redirects to a backend" do
    session.authorize("", "API_TOKEN")

    @ex.should_receive(:exchange).with(
      "backend.cedar",
      hash_including(app_name: "code-staging", push_api_url: "https://code.heroku.com/pushes"),
      {:name => "code-staging", timeout: 10}
    ).and_return(hostname: "10.92.38.48:6291", exchange_key: "ex.abc123")
    @ex.should_receive(:exchange).with("ex.abc123", {}, {timeout: 120})

    FakeWeb.register_uri(:get, "http://:API_TOKEN@10.92.38.48:6291/code-staging.git/info/refs", :body => "", :status => ["200", "OK"])

    session.get "/code-staging.git/info/refs"
    session.last_response.status.should == 200
  end

  it "posts a pack to a repo and redirects to a backend" do
    session.authorize("", "API_TOKEN")

    @ex.should_receive(:get).with("code-staging").and_return(hostname: "10.92.38.48:6291")

    FakeWeb.register_uri(:post, "http://:API_TOKEN@10.92.38.48:6291/code-staging.git/git-receive-pack", :body => "", :status => ["200", "OK"])

    session.post "/code-staging.git/git-receive-pack"
    session.last_response.status.should == 200
  end

  it "proxies *.code.heroku.com to a dev cloud release API" do
    @ex.stub!(:exchange).and_return(hostname: "10.92.38.48:6291", exchange_key: "ex.abc123")
    session("staging.code.heroku.com")

    @ex.should_receive(:exchange) do |key, data, opts|
      data[:metadata]["release_url"].should == "https://SECRET_KEY@api.staging.herokudev.com/apps/code/1905640"
    end

    session.authorize("", "API_TOKEN")
    session.get "/code-staging.git/info/refs"
    session.last_response.status.should == 200
  end

  it "exchanges with a bamboo backend based on metadata" do
    FakeWeb.register_uri(:get, "https://:API_TOKEN@api.heroku.com/apps/code-staging/releases/new", :body => JSON.dump(metadata(stack: "bamboo")), :status => ["200", "OK"])
    session.authorize("", "API_TOKEN")

    @ex.should_receive(:exchange).with(
      "backend.bamboo",
      hash_including(app_name: "code-staging", push_api_url: "https://code.heroku.com/pushes"),
      {:name => "code-staging", timeout: 10}
    ).and_return(hostname: "10.92.38.48:6291", exchange_key: "ex.abc123")
    @ex.should_receive(:exchange).with("ex.abc123", {}, {timeout: 120})

    FakeWeb.register_uri(:get, "http://:API_TOKEN@10.92.38.48:6291/code-staging.git/info/refs", :body => "", :status => ["200", "OK"])

    session.get "/code-staging.git/info/refs"
    session.last_response.status.should == 200
  end
end