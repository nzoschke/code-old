module Code
  class Exchange
    def initialize
    end

    def db
      @db ||= {}
    end

    def enqueue(key, data={})
    end

    def dequeue(key)
    end

    def reply(key, data={})
    end

    def send(key, data={})
      raise RuntimeError if db[key]
      db[key] = data
    end

    def receive(key)
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