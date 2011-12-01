require "./spec/spec_helper"

describe "Code::Models::Push" do
  before(:each) { Code.reload_models }
  after(:each)  { Sequel::DATABASES[0].disconnect }

  it "has a data model for metadata and logs for a push operation" do
    p = Code::Models::Push.new
    p.columns.should == [
      :id,
      :app_id, :app_name, :user_email,
      :stack, :flags, :heroku_host,
      :buildpack_url, :framework, :compile, :release, :debug_log, :exit_status,
      :started_at, :finished_at
    ]
  end
end
