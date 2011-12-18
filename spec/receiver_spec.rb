require "./spec/spec_helper"

describe Code::Receiver do
  before(:all) do
    r1, w1 = IO.pipe
    @redis_pid = Process.spawn("ruby-redis", :out => w1)
    r1.readpartial(1024) # block until server flushes logs with pid

    r2, w2 = IO.pipe
    @server_pid = Process.spawn("bin/receiver", :out => w2, :err => w2)
    r2.readpartial(1024) # block until server flushes logs with pid
  end

  after(:all) do
    Process.kill("TERM", @redis_pid)
    Process.wait(@redis_pid)

    Process.kill("TERM", @server_pid)
    Process.wait(@server_pid)
  end

  before do
    @logs = []
    Log.stub!(:write).and_return { |log| @logs << log }

    ENV["LOG_TOKEN"] = "t.abc123"
    ENV["GIT_DIR"] = File.expand_path(File.join(__FILE__, "..", "fixtures", "rack"))
    @r = Code::Receiver.new(data: { metadata: {"stack" => "cedar", "env" => {}} })
    `rm -rf #{WORK_DIR}`
    @r.unstow_repo
  end

  it "receives a push with no refs" do
    out = `git push http://localhost:5000/rackapp.git 2>&1`
    out.should =~ /Everything up-to-date/
  end

  it "receives a push with new refs and compiles it" do
    out = `git push http://localhost:5000/rackapp.git master 2>&1`
    out.should =~ /-----> Heroku receiving push/
  end
end