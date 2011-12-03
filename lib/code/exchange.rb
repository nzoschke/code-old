$:.delete_if { |p| p =~ /ruby-redis/ } # ruby-redis messes up Redis module; remove from path

require "redis"
require "yaml"

module Code
  class Exchange
    instrumentable do
      def initialize
      end

      def redis
        @redis ||= Redis.connect(:url => ENV["REDIS_URL"])
      end

      def generate_key(prefix="ex")
        "#{prefix}.#{SecureRandom.hex(8)}"
      end

      def hostname
        "localhost:#{ENV["PORT"]}"
      end

      def enqueue(key, data={})
        data.merge!(created_at: Time.now, exchange_key: generate_key)
        redis.rpush(key, YAML.dump(data))
        data
      end

      def dequeue(key, opts={})
        opts.reverse_merge!(timeout: 1)

        k, v = redis.blpop(key, opts[:timeout])
        YAML.load(v) if v
      end

      def reply(data)
        data.reverse_merge!(hostname: hostname)
        redis.rpush(data[:exchange_key], YAML.dump(data))
      end

      def exchange(key, data={}, opts={})
        opts.reverse_merge!(name: nil, timeout: 1)

        d = enqueue(key, data)
        r = dequeue(d[:exchange_key], opts)
        raise RuntimeError.new("no backend") unless r
        set(opts[:name], r) if opts[:name]
        r
      end

      def send(key, data={})
        raise RuntimeError unless redis.setnx(key, YAML.dump(data))
      end

      def receive(key)
        YAML.load(redis.get(key))
      end

      def set(key, value)
        redis.hset("exchanges", key, YAML.dump(value))
      end

      def get(key)
        v = redis.hget("exchanges", key)
        YAML.load(v) if v
      end

      def del(key)
        redis.hdel("exchanges", key)
      end
    end

    Log.instrument(self, :connect)
    Log.instrument(self, :enqueue)
    Log.instrument(self, :dequeue)
    Log.instrument(self, :exchange)
  end

end

