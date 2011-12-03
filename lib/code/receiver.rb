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
        monitor_git
        stow_repo
        self_destruct
      end

      def monitor_queue
        begin
          @data = exchange.dequeue("backend.cedar", timeout: 10)
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
        exchange.reply(d)
      end

      def monitor_git
        loop do
          flag = File.exists? "#{WORK_DIR}/.tmp/exit"
          Log.log(monitor_git: true, empty: !flag.to_s)
          flag ? break : sleep(5)
        end
      end

      def stow_repo
        `bin/stow-repo #{WORK_DIR} "#{data[:metadata]["repo_put_url"]}"`
        `bin/post-logs #{WORK_DIR} "#{data[:push_api_url]}"`
      end

      def self_destruct
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