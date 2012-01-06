require "./spec/spec_helper"

describe "Code::Web::Director" do
  include Code::Web::Helpers

  before do
    @ex = mock("exchange")
    Code::Exchange.stub!(:new).and_return(@ex)

    metadata = {
      "env"               => {"BUILDPACK_URL" => "https://github.com/heroku/heroku-buildpack-ruby.git"},
      "heroku_log_token"  => "t.8d3d88ea-31e5-47e5-9fac-1748101d05bc",
      "id"                => 1905640,
      "repo_get_url"      => "http://s3-external-1.amazonaws.com/heroku_repos/heroku.com/1905640.tgz",
      "repo_put_url"      => "http://s3-external-1.amazonaws.com/heroku_repos/heroku.com/1905640.tgz",
      "release_url"       => "https://SECRET_KEY@api.heroku.com/apps/code/1905640",
      "slug_put_url"      => "http://s3-external-1.amazonaws.com/herokuslugs/heroku.com/HASH",
      "user_email"        => "noah@heroku.com",
      "stack"             => "cedar"
    }
    staging_metadata = metadata.inject({}) { |h, (k,v)| h[k] = v.sub("heroku.com", "staging.herokudev.com") if v.is_a? String; h }

    FakeWeb.register_uri(:get, "https://api.heroku.com/apps/code-staging/releases/new", :body => "Unauthorized", :status => ["401", "Unauthorized"])
    FakeWeb.register_uri(:get, "https://:API_TOKEN@api.heroku.com/apps/code-staging/releases/new", :body => JSON.dump(metadata), :status => ["200", "OK"])
    FakeWeb.register_uri(:get, "https://:API_TOKEN@api.staging.herokudev.com/apps/code-staging/releases/new", :body => JSON.dump(staging_metadata), :status => ["200", "OK"])
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
end