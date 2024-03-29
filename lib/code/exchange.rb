$:.delete_if { |p| p =~ /ruby-redis/ } # ruby-redis messes up Redis module; remove from path

require "redis"
require "yaml"
require "socket"

module Code
  class Exchange
    class ReplyError < RuntimeError; end;

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
        local_ip = UDPSocket.open { |s| s.connect("64.233.187.99", 1); s.addr.last }
        "#{local_ip}:#{ENV["PORT"]}"
      end

      def enqueue(key, data={})
        data.merge!(created_at: Time.now, exchange_key: generate_key)
        redis.rpush(key, YAML.dump(data))
        data
      end

      def dequeue(key, opts={})
        opts.reverse_merge!(timeout: 1)

        k, v = redis.blpop(key, opts[:timeout])
        v ? YAML.load(v) : nil
      end

      def reply(data)
        data.reverse_merge!(hostname: hostname)
        redis.rpush(data[:exchange_key], YAML.dump(data))
      end

      def exchange(key, data={}, opts={})
        opts.reverse_merge!(name: nil, timeout: 1)

        d = enqueue(key, data)
        r = dequeue(d[:exchange_key], opts)
        if !r
          redis.lrem(key, 1, YAML.dump(d))
          raise ReplyError.new("No reply on #{d[:exchange_key]} within #{opts[:timeout]}s")
        end
        set(opts[:name], r) if opts[:name]
        r
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

    Log.instrument(self, :enqueue,  eval: "{hostname: hostname, key: args[0]}")
    Log.instrument(self, :dequeue,  eval: "{hostname: hostname, key: args[0]}")
    Log.instrument(self, :reply,    eval: "{hostname: hostname, key: args[0]}")
    Log.instrument(self, :exchange, eval: "{hostname: hostname, key: args[0]}")
    Log.instrument(self, :set,      eval: "{key: args[0], value: args[1]}")
  end
end

