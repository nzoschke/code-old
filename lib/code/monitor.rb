module Code
  class Monitor
    attr_reader :cmd, :num_processes, :processes, :threads

    def initialize(cmd)
      @cmd = cmd
      @num_processes = (ENV["NUM_PROCESSES"] || 1).to_i
      @processes = []
      @threads = []
    end

    def run!
      begin
        loop do
          start_all
          sleep 10
        end
      rescue SystemExit, Interrupt, SignalException => e
        kill_all
      end
    end

    def start(env={})
      spawn(cmd, env)
    end

    def start_all
      (num_processes - poll.length).times { start(generate_env) }
      processes
    end

    def kill_all
      processes.each { |p| kill p }
      threads.each   { |t| t.join }
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

    def spawn(cmd, env={})
      pid = Process.spawn(env, cmd)
      t   = Process.detach(pid)
      @processes  << pid
      @threads    << t
      pid
    end

    def kill(pid)
      Process.kill("TERM", pid)
      Process.wait(pid) rescue nil
    end
  end
end