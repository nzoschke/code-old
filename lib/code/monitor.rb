module Code
  class Monitor
    attr_reader :num_processes, :processes

    def initialize
      @num_processes = ENV["NUM_PROCESSES"] || 5
      @processes = []
    end

    def start(cmd, env={})
      pid = spawn(cmd, env)
      @processes << pid
      pid
    end

    def start_all(cmd)
      (num_processes - poll(cmd).length).times { start(cmd, generate_env) }
    end

    def kill_all
      processes.each { |pid| kill pid }
    end

    def poll(cmd)
      processes
    end

    def gc
    end

    def generate_env
      {"PORT" => (5000..6000).to_a.sample.to_s}
    end

    def spawn(cmd, env={})
      puts env.inspect
      Process.spawn(env, cmd)
    end

    def kill(pid)
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end