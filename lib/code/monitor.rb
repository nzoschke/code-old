module Code
  class Monitor
    attr_reader :cmd, :num_processes, :processes

    def initialize(cmd)
      @cmd = cmd
      @num_processes = ENV["NUM_PROCESSES"].to_i rescue 1
      @processes = []
    end

    def start(env={})
      pid = Process.spawn(env, cmd)
      @processes << pid
      pid
    end

    def start_all
      (num_processes - poll.length).times { start(generate_env) }
      processes
    end

    def kill_all
      processes.each { |pid| kill pid }
    end

    def poll
      @processes.select! { |pid| Process.kill(0, pid) rescue false }
      @processes
    end

    def gc
    end

    def generate_env
      {"PORT" => (5000..6000).to_a.sample.to_s}
    end

    def kill(pid)
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end