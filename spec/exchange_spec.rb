require "./spec/spec_helper"

describe "Code::Exchange" do
  before(:all) do
    r, w = IO.pipe
    @redis_pid = Process.spawn("ruby-redis", :out => w)
    r.readpartial(1024) # block until server flushes logs with pid
  end

  after(:all) do
    Process.kill("TERM", @redis_pid)
    Process.wait(@redis_pid)
  end

  before do
    @logs = []
    Log.stub!(:write).and_return { |log| @logs << log }

    @ex = Code::Exchange.new
    @ex.stub!(:hostname).and_return("10.92.38.48:6291")
    @ex.redis.flushdb
  end

  it "exchanges with a backend, and caches the exchange key" do
    _ex = Code::Exchange.new
    Thread.new { _ex.reply _ex.dequeue("backend.cedar") }
    @ex.exchange("backend.cedar", {app_name: "noah"}, name: "noah")
  end

  it "logs around exchange" do
    _ex = Code::Exchange.new
    _ex.stub!(:hostname).and_return("10.92.38.48:9242")

    Thread.new { _ex.reply _ex.dequeue("backend.cedar") }
    @ex.exchange("backend.cedar", {app_name: "noah"}, name: "noah")

    @logs.should include "exchange hostname=10.92.38.48:6291 key=backend.cedar at=start"
    @logs.should include "enqueue hostname=10.92.38.48:6291 key=backend.cedar at=start"
    @logs.should include "dequeue hostname=10.92.38.48:9242 key=backend.cedar at=start"
  end

  it "raises an exception and deletes job if exchange failed" do
    proc { @ex.exchange("backend.cedar", {app_name: "noah"}, name: "noah", timeout: 1) }.should raise_error(Code::Exchange::ReplyError)
    @ex.redis.llen("backend.cedar").should == 0
  end

  it "enqueues a message and gets a reply on a unique exchange key" do
    @ex.stub!(:generate_key).and_return("ex.abc123")

    @ex.enqueue("backend.cedar", {app_name: "noah"})  # director
    @ex.reply(@ex.dequeue("backend.cedar"))           # backend
    data = @ex.dequeue("ex.abc123")                   # director

    data.should include_hash({app_name: "noah", hostname: "10.92.38.48:6291", exchange_key: "ex.abc123"})
  end

  it "maps an app name to a unique exchange key" do
    @ex.set("noah", "ex.abc123")
    @ex.get("noah").should == "ex.abc123"
  end

  it "expires an app name and exchange key mapping" do
    @ex.set("noah", "ex.abc123")
    @ex.del("noah")
    @ex.get("noah").should == nil
  end
end