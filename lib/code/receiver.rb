require "yaml"
require "./lib/code"

module Code
  class Receiver
    instrumentable do
      attr_reader :data, :exchange
    
      def initialize
        @exchange = Exchange.new

        monitor_queue
        unstow_repo
        reply_exchange
        monitor_git && stow_repo
        self_destruct
      end

      def monitor_queue
        begin
          if d = exchange.dequeue("backend.cedar", timeout: 10)
            age = Time.now - d[:created_at]
            @data = d if age < 10
            Log.log(monitor_queue: true, empty: "false", exchange_key: d[:exchange_key], age: age)
          else
            Log.log(monitor_queue: true, empty: "true")
          end
        end while !@data
        exchange.reply(data)
      end

      def unstow_repo
        `bin/unstow-repo #{WORK_DIR} "#{data[:metadata]["repo_get_url"]}"`

        # persist metadata and env to the disk
        File.open("#{WORK_DIR}/.tmp/metadata.yml", "w") { |f| f.write YAML.dump data[:metadata] }
        File.open("#{WORK_DIR}/.tmp/build_env", "w") do |f|
          data[:metadata]["env"].merge("PATH" => ENV["PATH"]).each do |k,v|
            v = v.gsub(/'/, "\\\\'")  # escape any single quotes with backslash
            f.write("#{k}=$'#{v}'\n") # use bash $'...' ANSI-C quoting
          end
        end
      end

      def reply_exchange
        d = exchange.dequeue(data[:exchange_key], timeout: 10)
        d ? exchange.reply(d) : self_destruct # if frontend disappeared, destroy repo
      end

      def monitor_git
        started = Time.now
        loop do
          age = Time.now - started
          info_start      = File.exists? "#{WORK_DIR}/.tmp/info_start"
          rpc_start       = File.exists? "#{WORK_DIR}/.tmp/rpc_start"
          rpc_exit        = File.exists? "#{WORK_DIR}/.tmp/rpc_exit"
          compile_start   = File.exists? "#{WORK_DIR}/.tmp/start"
          compile_exit    = File.exists? "#{WORK_DIR}/.tmp/exit"
          exit_status     = File.read("#{WORK_DIR}/.tmp/exit").strip.to_i rescue -1

          Log.log(monitor_git: true, age: age, info_start: info_start.to_s, rpc_start: rpc_start.to_s, compile_start: compile_start.to_s, compile_exit: compile_exit.to_s, rpc_exit: rpc_exit.to_s)

          return true  if rpc_exit && exit_status == 0  # successful compile, stow repo
          return false if rpc_exit                      # fetch or unsuccessful compile, throw away
          return false if !rpc_start && age > 30        # noop, throw away
          sleep 5
        end
      end

      def stow_repo
        `bin/stow-repo #{WORK_DIR} "#{data[:metadata]["repo_put_url"]}"`
        `bin/post-logs #{WORK_DIR} "#{data[:push_api_url]}"`
      end

      def self_destruct
        puts `find #{WORK_DIR}/.tmp | xargs --verbose -n1 cat`
        Process.kill("TERM", $$)
      end
    end

    Log.instrument(self, :monitor_queue,  eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :unstow_repo,    eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :reply_exchange, eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :monitor_git,    eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :stow_repo,      eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :self_destruct,  eval: "{hostname: exchange.hostname}")
  end
end