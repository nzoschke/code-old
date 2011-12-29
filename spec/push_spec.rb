require "./spec/spec_helper"

describe Code::Models::Push do
  before do
    @p = Code::Models::Push.create
  end

  it "has a data model for metadata and logs for a push operation" do
    @p.columns.should == [
      :id,
      :app_id, :app_name, :user_email,
      :stack, :flags, :heroku_host,
      :buildpack_url, :framework,
      :detect, :compile, :release, :debug, :exit,
      :started_at, :finished_at,
      :created_at, :updated_at
    ]
  end

  it "sets a created/updated timestamps on save" do
    @p.created_at.should_not == nil
    @p.updated_at.should == nil

    @p.save
    @p.updated_at.should_not == nil
  end

  it "serializes to json" do
    @p.to_json.should =~ /Code::Models::Push/
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
        metadata:     Rack::Test::UploadedFile.new("#{fixtures_dir}/metadata.yml",  "text/plain"),
        detect:       Rack::Test::UploadedFile.new("#{fixtures_dir}/detect.log",    "text/plain"),
        compile:      Rack::Test::UploadedFile.new("#{fixtures_dir}/compile.log",   "text/plain"),
        release:      Rack::Test::UploadedFile.new("#{fixtures_dir}/release.log",   "text/plain"),
        debug:        Rack::Test::UploadedFile.new("#{fixtures_dir}/debug.log",     "text/plain"),
        exit:         Rack::Test::UploadedFile.new("#{fixtures_dir}/exit",          "text/plain")

      last_response.status.should == 200

      p = Code::Models::Push.last
      p.app_id.should     == 1905640
      p.app_name.should   == "code-staging"
      p.stack.should      == "cedar"
      p.framework.should  == "Ruby/Rack"
      p.detect.should     == "Ruby/Rack"
      p.compile.should    =~ /Heroku receiving push/
      p.release.should    =~ /process_types/
      p.debug.should      =~ /GIT_DIR/
      p.exit.should       == 0
    end
  end
end
