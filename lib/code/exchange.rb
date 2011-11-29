module Code
  class Exchange
    def initialize
    end

    def db
      @db ||= {}
    end

    def enqueue(key, data={})
      db[key] ||= []
      db[key] << data
    end

    def dequeue(key)
      db[key].pop
    end

    def reply(data)
      enqueue("ex.abc123", {app_name: "noah", hostname: "route.heroku.com:3117", exchange_key: "ex.abc123"})
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