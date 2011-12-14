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

  class HerokuMonitor < Monitor
    instrumentable do
      def heroku
        RestClient::Resource.new("https://api.heroku.com",
          user:     "",
          password: ENV["HEROKU_PASSWORD"],
          headers:  { accept: :json }
        )["apps"][ENV["HEROKU_APP"]]
      end

      def spawn(cmd, env={})
        r = JSON.parse heroku["ps"].post(command: cmd, type: cmd.split("/").last, attached: false, ps_env: env)
        heroku["routes/attach"].put("url" => URI.escape("tcp://" + env["HOSTNAME"]), "ps" => r["process"])
        r["upid"]
      end

      def poll
        r = JSON.parse heroku["ps"].get(accept: :json)
        upids = r.select { |a| a["command"] == cmd && ["starting", "up"].include?(a["state"]) }.map { |a| a["upid"]}
        Log.log(poll: true, num: upids.length)
        upids
      end

      def generate_env
        r = JSON.parse heroku["routes"].post({})
        {"HOSTNAME" => r["url"].gsub("tcp://", "")}
      end

      def gc
        ps = JSON.parse heroku["ps"].get(accept: :json)
        routes = JSON.parse heroku["routes"].get(accept: :json)

        active_processes = ps.select { |ps| ["starting", "up"].include? ps["state"] }.map { |ps| ps["process" ] }
        orphan_routes = routes.reject { |r| active_processes.include? r["ps"] }

        orphan_routes.each do |route|
          Log.log(gc: true, delete_route: true, url: route["url"])
          heroku["routes?url=#{URI.escape(route["url"])}"].delete
        end
      end

      def kill_all;  end # noops
      def kill(pid); end
    end

    Log.instrument(self, :spawn, eval: "{cmd: args[0], env: args[1].inspect}")
    Log.instrument(self, :poll)
    Log.instrument(self, :generate_env)
    Log.instrument(self, :gc)
  end
end