require "./spec/spec_helper"

class Test
  loggable do
    def initialize
      @port = 6379
    end

    def connect(url, opts={})
      puts "connecting to #{url} with #{opts.inspect}"
    end
  end
end

describe "Log" do
  it "prints an ordered hash of various data types as a string" do
    STDOUT.should_receive(:puts).with(%q(true false=false str=string quote='"woah" dude!' punc="#$@&*?!!" sym=sym float=3.140 num=42 cls=Test mod=Log))
    Log.log(
      true:   true,
      false:  false,
      str:    "string",
      quote:  '"woah" dude!',
      punc:   '#$@&*?!!',
      sym:    :sym,
      float:  3.14,
      num:    42,
      cls:    Test,
      mod:    Log
    )
  end

  it "doesnt log by default" do
    STDOUT.should_receive(:puts).with("connecting to redis://localhost:6379 with {:retry=>true}")
    Test.new.connect("redis://localhost:6379", retry: true)
  end

  it "instruments a method if specified" do
    STDOUT.should_receive(:puts).with("connect at=start")
    STDOUT.should_receive(:puts).with("connecting to redis://localhost:6379 with {:retry=>true}")
    STDOUT.should_receive(:puts).with("connect at=finish elapsed=0.000")
    Log.instrument(Test, :connect)
    Test.new.connect("redis://localhost:6379", retry: true)
  end

  it "instruments local data with eval" do
    STDOUT.should_receive(:puts).with("connect test port=6379 at=start")
    STDOUT.should_receive(:puts).with("connecting to redis://localhost:6379 with {:retry=>true}")
    STDOUT.should_receive(:puts).with("connect test at=finish elapsed=0.000")
    Log.instrument(Test, :connect, test: true, eval: "{port: @port}")
    Test.new.connect("redis://localhost:6379", retry: true)
  end

  it "merges hashes" do
    Log.merge({a: :a}, {b: :b}, {c: :c}).to_s.should == "{:a=>:a, :b=>:b, :c=>:c}"
  end
end