module Code
  class Exchange
    def initialize
    end

    def db
      @db ||= {}
    end

    def generate_key(prefix="ex")
      "ex.abc123"
    end

    def hostname
      "route.heroku.com:3117"
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
      db[key] = value
    end

    def get(key)
      db[key]
    end

    def del(key)
      db.delete(key)
    end
  end
end