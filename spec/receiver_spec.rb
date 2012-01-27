require "./spec/spec_helper"

describe Code::Receiver do
  before(:all) do
    ENV["LOG_FILE"] = "/dev/null"

    r1, w1 = IO.pipe
    @redis_pid = Process.spawn("ruby-redis", :out => w1, :err => w1)
    r1.readpartial(1024).should =~ /ready to accept connections on port 6379/ # block until server flushes logs with pid

    @r2, w2 = IO.pipe
    @server_pid = Process.spawn("bin/receiver", :out => w2, :err => w2)
    @r2.readpartial(1024).should =~ /listening on addr=0.0.0.0:5000/ # block until server flushes logs with pid
  end

  after(:all) do
    Process.kill("TERM", @redis_pid)
    Process.wait(@redis_pid)

    Process.kill("TERM", @server_pid)
    Process.wait(@server_pid)
  end

  before do
    ENV["LOG_TOKEN"] = "t.abc123"
    ENV["GIT_DIR"] = File.expand_path(File.join(__FILE__, "..", "fixtures", "rack.git"))
    @r = Code::Receiver.new(data: { metadata: {"stack" => "cedar", "env" => {}} })
    `rm -rf #{WORK_DIR}`
  end

  context "interactive http push" do
    before { @r.unstow_repo } # set up an empty repo

    it "receives a push with no refs" do
      out = `git push http://localhost:5000/rack.git 2>&1`
      out.should =~ /Everything up-to-date/
    end

    it "receives a push with new refs and compiles it" do
      out = `git push http://localhost:5000/rack.git master 2>&1`
      out.should =~ /-----> Heroku receiving push/
      out.should =~ /-----> Launching.../

      # app dumps build env; assert that it was cleaned
      out.should     =~ /LOG_TOKEN/
      out.should_not =~ /DATABASE_URL/
      out.should_not =~ /REDIS_URL/
    end
  end

  context "background compile" do
    it "compiles a slug without a push when :action=compile" do
      meta = metadata
      meta["repo_get_url"] = ENV["GIT_DIR"] # unstow from fixture directory

      app_name = meta["url"].split(".")[0]
      major_stack = meta["stack"].split("-")[0]

      exchange = Code::Exchange.new
      d = exchange.exchange("backend.#{major_stack}", {
        app_name:     app_name,
        push_api_url: "https://code.heroku.com/pushes",
        metadata:     meta,
        action:       "compile"
      }, name: app_name, timeout: 10)

      @r.monitor_work

      out = File.read "#{WORK_DIR}/.tmp/compile.log"
      out.should =~ /-----> Heroku receiving push/
      out.should =~ /-----> Launching.../
    end
  end
end