require "./lib/code"

describe "Code::Exchange" do
  before do
    @ex = Code::Exchange.new
    @ex.redis.flushdb
  end

  it "exchanges with a backend, and caches the exchange key" do
    _ex = Code::Exchange.new
    Thread.new { _ex.reply _ex.dequeue("backend.cedar") }
    @ex.exchange("backend.cedar", {app_name: "noah"}, name: "noah")
  end

  it "enqueues a message and gets a reply on a unique exchange key" do
    @ex.should_receive(:generate_key).and_return("ex.abc123")
    @ex.should_receive(:hostname).and_return("route.heroku.com:3117")
    Time.should_receive(:now).and_return(0)

    @ex.enqueue("backend.cedar", {app_name: "noah"})  # director
    @ex.reply(@ex.dequeue("backend.cedar"))           # backend
    data = @ex.dequeue("ex.abc123")                   # director

    data.should == {app_name: "noah", created_at: 0, hostname: "route.heroku.com:3117", exchange_key: "ex.abc123"}
  end

  it "communicates over an exchange key" do
    @ex.send("ex.abc123", {app_name: "noah"}) # director
    data = @ex.receive("ex.abc123")           # backend
    data.should == {app_name: "noah"}
  end

  it "fails to communicate if backend did not receive last message" do
    @ex.send("ex.abc123", {app_name: "noah"})
    proc { @ex.send("ex.abc123", {app_name: "noah"}) }.should raise_error
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