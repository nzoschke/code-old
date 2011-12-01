require "./spec/spec_helper"

describe Code::Models::Push do
  before(:each) { Sequel::Migrator.apply(Sequel::DATABASES[0], "db/migrations") }
  after(:each)  { Sequel::DATABASES[0].disconnect }

  include Code::Models

  it "has a data model for metadata and logs for a push operation" do
    p = Push.new
    p.columns.should == [
      :id,
      :app_id, :app_name, :user_email,
      :stack, :flags, :heroku_host,
      :buildpack_url, :framework,
      :detect, :compile, :release, :debug, :exit_status,
      :started_at, :finished_at
    ]
  end

  context Code::Web::PushAPI do
    include Rack::Test::Methods

    def app
      Rack::Builder.new do
        map("/pushes") { run Code::Web::PushAPI }
      end
    end

    it "has an API for saving push data" do
      fixtures_dir = File.expand_path(File.join(__FILE__, "..", "fixtures"))

      post "/pushes",
        app_id:         31337,
        app_name:       "code",
        user_email:     "noah@heroku.com",
        heroku_host:    "heroku.com",
        buildpack_url:  "https://github.com/heroku/heroku-buildpack-ruby.git",
        detect:         Rack::Test::UploadedFile.new("#{fixtures_dir}/detect.log",   "text/plain"),
        compile:        Rack::Test::UploadedFile.new("#{fixtures_dir}/compile.log",  "text/plain"),
        release:        Rack::Test::UploadedFile.new("#{fixtures_dir}/release.log",  "text/plain"),
        debug:          Rack::Test::UploadedFile.new("#{fixtures_dir}/debug.log",    "text/plain"),
        exit_status:    0

      last_response.status.should == 200

      p = Push[1]
      p.app_id.should       == 31337
      p.app_name.should     == "code"
      p.stack.should        == "cedar"
      p.framework.should    == "Ruby/Rack"
      p.detect.should       == "Ruby/Rack"
      p.compile.should      =~ /Heroku receiving push/
      p.release.should      =~ /process_types/
      p.debug.should        =~ /GIT_DIR/
      p.exit_status.should  == 0
    end
  end
end
