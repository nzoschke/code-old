require "json"
require "redis"

module Code
  class Exchange
    def initialize
    end

    def redis
      @redis ||= Redis.connect(:url => ENV["REDIS_URL"])
    end

    def db
      @db ||= {}
    end

    def generate_key(prefix="ex")
      "#{prefix}.#{SecureRandom.hex(8)}"
    end

    def hostname
      `hostname`.strip
    end

    def enqueue(key, data={})
      db[key] ||= []
      db[key] << data.merge(exchange_key: generate_key)
    end

    def dequeue(key)
      db[key].pop
    end

    def reply(data)
      db[data[:exchange_key]] = [data.merge(hostname: hostname)]
    end

    def send(key, data={})
      raise RuntimeError if db[key]
      db[key] = data
    end

    def receive(key)
      db[key]
    end

    def set(key, value)
      redis.hset("exchanges", key, value)
    end

    def get(key)
      redis.hget("exchanges", key)
    end

    def del(key)
      redis.hdel("exchanges", key)
    end
  end
end