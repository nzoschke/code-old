module Code
  class Monitor
    attr_reader :num_processes, :processes

    def initialize
      @num_processes = ENV["NUM_PROCESSES"] || 5
      @processes = []
    end

    def start(cmd, env={})
      pid = (5000..6000).to_a.sample
      @processes << pid
      pid
    end

    def start_all(cmd)
      (num_processes - poll(cmd).length).times { start(cmd, generate_env) }
    end

    def poll(cmd)
      processes
    end

    def gc
    end

    def generate_env
      {PORT: (5000..6000).to_a.sample}
    end
  end
end