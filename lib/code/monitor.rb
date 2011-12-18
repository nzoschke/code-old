require "json"
require "restclient"
require "uri"

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
        i = 0
        loop do
          start_all
          gc if (i+=1)%10 == 0
          sleep 30
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

  class HerokuMonitor < Monitor
    instrumentable do
      def heroku
        RestClient::Resource.new("https://api.heroku.com",
          user:     "",
          password: ENV["HEROKU_API_KEY"],
          headers:  { accept: :json }
        )["apps"][ENV["HEROKU_APP"]]
      end

      def spawn(cmd, env={})
        r = JSON.parse heroku["ps"].post(command: cmd, type: cmd.split("/").last, attached: false)
        r["upid"]
      end

      def poll
        r = JSON.parse heroku["ps"].get
        upids = r.select { |a| a["command"] == cmd && ["starting", "up"].include?(a["state"]) }.map { |a| a["upid"] }
        Log.log(poll: true, needed: num_processes, up: upids.length)
        upids
      end

      def kill_all;     end  # noops
      def kill(pid);    end
    end

    Log.instrument(self, :spawn, eval: "{cmd: args[0], env: args[1].inspect}")
    Log.instrument(self, :poll)
  end
end