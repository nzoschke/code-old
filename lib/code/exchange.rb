require "yaml"
require "redis"

module Code
  class Exchange
    def initialize
    end

    def redis
      @redis ||= Redis.connect(:url => ENV["REDIS_URL"])
    end

    def generate_key(prefix="ex")
      "#{prefix}.#{SecureRandom.hex(8)}"
    end

    def hostname
      `hostname`.strip
    end

    def enqueue(key, data={})
      data.merge!(exchange_key: generate_key)
      redis.rpush(key, YAML.dump(data))
    end

    def dequeue(key)
      k, v = redis.blpop(key, 1)
      YAML.load(v) if v
    end

    def reply(data)
      data.merge!(hostname: hostname)
      redis.rpush(data[:exchange_key], YAML.dump(data))
    end

    def send(key, data={})
      raise RuntimeError unless redis.setnx(key, YAML.dump(data))
    end

    def receive(key)
      YAML.load(redis.get(key))
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