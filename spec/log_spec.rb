class Module
  def loggable(&blk)
    include Module.new(&blk)
  end
end

module Log
  extend self

  def log(*datas)
    data = merge(*datas)
    msg  = unparse data
    mtx.synchronize do
      STDOUT.puts msg
    end
  end

  def log_exception(data, e)
    log data.merge(exception: true, class: e.class, message: e.message, exception_id: e.object_id.abs)
    e.backtrace.reverse.each do |line|
      log data.merge(exception: true, exception_id: e.object_id.abs, site: line.gsub(/[`'"]/, ""))
    end
  end

  def around(cls, method, data={})
    data = {method => true}.merge(data)
    eval = data.delete(:eval) || "{}"

    cls.class_eval do
      define_method method do |*args|
        start = Time.now
        ret = nil
        Log.log(data, eval(eval), {:at => :start})
        begin
          ret = super(*args)
        rescue StandardError, Timeout::Error => e
          Log.log data.merge(at: :exception, reraise: true, class: e.class, message: e.message, exception_id: e.object_id.abs, elapsed: Time.now - start)
          raise e
        end
        Log.log(data, {:at => :finish, elapsed: Time.now - start})
        ret
      end
    end
  end

  def merge(*hashes)
    hashes.inject({}){|hh, h| hh = hh.merge(h); hh}
  end

  def mtx
    @mtx ||= Mutex.new
  end

  def unparse(data)
    data.map do |(k, v)|
      if (v == true)
        k.to_s
      elsif (v == false)
        "#{k}=false"
      elsif (v.is_a?(String) && v.include?("\""))
        "#{k}='#{v}'"
      elsif (v.is_a?(String) && (v !~ /^[a-zA-Z0-9\:\.\-\_]+$/))
        "#{k}=\"#{v}\""
      elsif (v.is_a?(String) || v.is_a?(Symbol))
        "#{k}=#{v}"
      elsif v.is_a?(Float)
        "#{k}=#{format("%.3f", v)}"
      elsif v.is_a?(Numeric) || v.is_a?(Class) || v.is_a?(Module)
        "#{k}=#{v}"
      end
    end.compact.join(" ")
  end
end

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

  it "doesnt log normally" do
    STDOUT.should_receive(:puts).with("connecting to redis://localhost:6379 with {:retry=>true}")
    Test.new.connect("redis://localhost:6379", retry: true)
  end

  it "logs around a method" do
    STDOUT.should_receive(:puts).with("connect at=start")
    STDOUT.should_receive(:puts).with("connecting to redis://localhost:6379 with {:retry=>true}")
    STDOUT.should_receive(:puts).with("connect at=finish elapsed=0.000")
    Log.around(Test, :connect)
    Test.new.connect("redis://localhost:6379", retry: true)
  end

  it "experimentally logs local data from outside with eval" do
    STDOUT.should_receive(:puts).with("connect test port=6379 at=start")
    STDOUT.should_receive(:puts).with("connecting to redis://localhost:6379 with {:retry=>true}")
    STDOUT.should_receive(:puts).with("connect test at=finish elapsed=0.000")
    Log.around(Test, :connect, test: true, eval: "{port: @port}")
    Test.new.connect("redis://localhost:6379", retry: true)
  end

  it "merges hashes" do
    Log.merge({a: :a}, {b: :b}, {c: :c}).to_s.should == "{:a=>:a, :b=>:b, :c=>:c}"
  end
end