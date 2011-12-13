require "./spec/spec_helper"

describe Code::Receiver do
  it "starts a git HTTP backend" do
    @s = mock("unicorn http server")
    Unicorn::HttpServer.should_receive(:new).with(an_instance_of(GitHttp::App), {:listeners=>[]}).and_return(@s)
    @s.should_receive(:start).and_return(@s)
    @s.should_receive(:join).and_return(@s)

    Code::Receiver.start_server!
  end

  context "server" do
    before(:all) do
      r1, w1 = IO.pipe
      @redis_pid = Process.spawn("bundle exec ruby-redis", :out => w1)
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
      @app_dir = File.expand_path(File.join(__FILE__, "..", "fixtures", "rackapp"))
    end

    it "receives a push, compiles a slug, and monitors the compile progress" do
      ENV["GIT_DIR"] = @app_dir
      out = `git push http://localhost:5000/rackapp.git 2>&1`
      puts out.inspect
    end
  end
end