require "./spec/spec_helper"

describe Code::Receiver do
  it "forks a unicorn server and starts a blocking monitor loop" do
    Process.should_receive(:fork)
    @r = mock("exchange monitor")
    Code::Receiver.should_receive(:new).and_return(@r)
    @r.should_receive(:start!)

    Code::Receiver.start!
  end

  it "starts a unicorn git HTTP server" do
    @s = mock("unicorn http server")
    Unicorn::HttpServer.should_receive(:new).with(
      an_instance_of(GitHttp::App),
      { listeners: [], timeout: 1800, worker_processes: 1 }
    ).and_return(@s)
    @s.should_receive(:start).and_return(@s)
    @s.should_receive(:join).and_return(@s)

    Code::Receiver.start_server!
  end

  context "server" do
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

      ENV["GIT_DIR"] = @app_dir = File.expand_path(File.join(__FILE__, "..", "fixtures", "rack"))
      @r = Code::Receiver.new(metadata: {"stack" => "cedar", "env" => {}})
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
end