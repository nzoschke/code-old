require "json"
require "redis"
require "securerandom"

class Hash
  def reverse_merge!(h)
    replace(h.merge(self))
  end
end

module Code
  class Exchange
    attr_reader :redis, :key

    def initialize
      @redis = Redis.connect(url: ENV["REDIS_URL"])
      @key = nil
    end

    def enqueue(queue, opts={})
      opts.reverse_merge!(
        data:     {},
        prefix:   "ex",
        timeout:  10
      )

      k = "#{opts[:prefix]}.#{SecureRandom.hex(8)}"
      opts[:data].merge!("exchange_key" => k)
      redis.rpush(queue, JSON.dump(opts[:data]))

      @key, v = redis.blpop(k, opts[:timeout])
      # TODO: delete queued job if no backend?
      v ? @key : nil
    end

    def dequeue(queue, opts={})
      opts.reverse_merge!(
        data:     {},
        timeout:  30
      )

      begin
        k, v = redis.blpop(queue, opts[:timeout])
      end while not v
      data = JSON.parse(v)

      @key = data["exchange_key"]
      redis.rpush(@key, JSON.dump(data))
    end

    def ping
      enqueue(key, prefix: key, timeout: 1)
    end

    def ack
      dequeue(key, timeout: 1)
    end
  end

  class Monitor
  end
end