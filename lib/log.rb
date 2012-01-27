class Module
  # define and include all block methods in an anonymous module
  # allowing Log.instrument to redefine and access via super
  # http://yehudakatz.com/2009/01/18/other-ways-to-wrap-a-method/
  def instrumentable(&blk)
    include Module.new(&blk)
  end
end

module Log
  extend self

  def log(*datas)
    data = merge(*datas)
    write(unparse data)
  end

  def file
    @file   = nil if @path != ENV["LOG_FILE"]     # 'close' file if path changed
    @path   = ENV["LOG_FILE"]                     # save path
    @file ||= File.open(@path, "a") rescue STDOUT # return or re-open file
  end

  def write(log)
    mtx.synchronize do
      file.puts log
      file.flush
    end
  end

  def log_exception(data, e)
    log data.merge(exception: true, class: e.class, message: e.message, exception_id: e.object_id.abs)
    e.backtrace.reverse.each do |line|
      log data.merge(exception: true, exception_id: e.object_id.abs, site: line.gsub(/[`'"]/, ""))
    end
  end

  def instrument(cls, method, data={})
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
          Log.log(data, {at: :exception, reraise: true, class: e.class, message: e.message, exception_id: e.object_id.abs, elapsed: Time.now - start})
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