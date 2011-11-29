require "./lib/code"

describe "Code::Exchange" do
  before do
    @ex = Code::Exchange.new
  end

  it "enqueues a message and gets a reply on a unique exchange key" do
    @ex.should_receive(:generate_key).with("ex").and_return("ex.abc123")
    @ex.should_receive(:hostname).and_return("route.heroku.com:3117")

    @ex.enqueue("backend.cedar", {app_name: "noah"})  # director
    @ex.reply(@ex.dequeue("backend.cedar"))           # backend
    data = @ex.dequeue("ex.abc123")                   # director

    data.should == {app_name: "noah", hostname: "route.heroku.com:3117", exchange_key: "ex.abc123"}
  end

  it "communicates over an exchange key" do
    @ex.send("ex.abc123", {app_name: "noah"}) # director
    data = @ex.receive("ex.abc123")           # backend
    data.should == {app_name: "noah"}
  end

  it "fails to communicate if backend did not receive last message" do
    @ex.send("ex.abc123", {app_name: "noah"})
    proc { @ex.send("ex.abc123", {app_name: "noah"}) }.should_raise Code::Exchange::ReceiveError
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

# xdescribe "Code::Exchange" do
#   before do
#     @redis = mock("redis")
#     Redis.stub!(:new).and_return(@redis)

#     @ex = Code::Exchange.new
#   end

#   it "sets and returns an exchange key after publishing to a queue and waiting for a reply" do
#     @redis.should_receive(:rpush).with("backend.cedar", /exchange_key/)
#     @redis.should_receive(:blpop).with(/ex.*/, 10).and_return(["ex.foo", "(data...)"])
#     @ex.enqueue("backend.cedar").should =~ /ex.*/
#     @ex.key.should =~ /ex.*/
#   end

#   it "sets and maintains a nil exchange key after publishing to a queue with no reply" do
#     @redis.should_receive(:rpush).with("backend.cedar", /exchange_key/)
#     @redis.should_receive(:blpop).with(/ex.*/, 10).and_return([nil, nil])
#     @ex.enqueue("backend.cedar").should == nil
#     @ex.key.should == nil
#   end

#   it "pings the exchange key" do
#     @ex.stub!(:key).and_return("ex.deadbeef")
#     @redis.should_receive(:rpush).with(/ex.deadbeef.*/, /exchange_key/)
#     @redis.should_receive(:blpop).with(/ex.deadbeef.*/, 1).and_return(["ex.deadbeef.deadbeef", "(data...)"])
#     @ex.ping
#   end

#   it "enqueues, then ping/acks" do
#     @redis.should_receive(:rpush).with("backend.cedar", /exchange_key/)
#     @redis.should_receive(:blpop).with(/ex.*/, 10).and_return(["ex.deadbeef", "(data...)"])
#     @ex.enqueue("backend.cedar")

#     @redis.should_receive(:rpush).with("ex.deadbeef", /exchange_key/)
#     @redis.should_receive(:blpop).with(/ex.deadbeef.*/, 1).and_return(["ex.deadbeef.deadbeef", "(data...)"])
#     @ex.ping

#     @redis.should_receive(:blpop).with(/ex.deadbeef.deadbeef/, 1).and_return(["ex.deadbeef.deadbeef", "(data...)"])
#     @ex.ack
#   end
# end