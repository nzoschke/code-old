require "./lib/code"

describe "Code::Exchange" do
  before do
    @redis = mock("redis")
    Redis.stub!(:new).and_return(@redis)

    @ex = Code::Exchange.new
  end

  it "sets and returns an exchange key after publishing to a queue and waiting for a reply" do
    @redis.should_receive(:rpush).with("backend.cedar", /exchange_key/)
    @redis.should_receive(:blpop).with(/ex.*/, 10).and_return(["ex.foo", "(data...)"])
    @ex.enqueue("backend.cedar").should =~ /ex.*/
    @ex.key.should =~ /ex.*/
  end

  it "sets and maintains a nil exchange key after publishing to a queue with no reply" do
    @redis.should_receive(:rpush).with("backend.cedar", /exchange_key/)
    @redis.should_receive(:blpop).with(/ex.*/, 10).and_return([nil, nil])
    @ex.enqueue("backend.cedar").should == nil
    @ex.key.should == nil
  end

  it "pings the exchange key" do
    @ex.stub!(:key).and_return("ex.deadbeef")
    @redis.should_receive(:rpush).with(/ex.deadbeef.*/, /exchange_key/)
    @redis.should_receive(:blpop).with(/ex.deadbeef.*/, 1).and_return(["ex.deadbeef.deadbeef", "(data...)"])
    @ex.ping
  end

  it "enqueues, then ping/acks" do
    @redis.should_receive(:rpush).with("backend.cedar", /exchange_key/)
    @redis.should_receive(:blpop).with(/ex.*/, 10).and_return(["ex.deadbeef", "(data...)"])
    @ex.enqueue("backend.cedar")

    @redis.should_receive(:rpush).with("ex.deadbeef", /exchange_key/)
    @redis.should_receive(:blpop).with(/ex.deadbeef.*/, 1).and_return(["ex.deadbeef.deadbeef", "(data...)"])
    @ex.ping

    @redis.should_receive(:blpop).with(/ex.deadbeef.deadbeef/, 1).and_return(["ex.deadbeef.deadbeef", "(data...)"])
    @ex.ack
  end
end