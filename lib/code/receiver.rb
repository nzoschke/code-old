require "yaml"
require "./lib/code"

module Code
  class Receiver
    instrumentable do
      def initialize
        @exchange = Exchange.new

        data = monitor_exchange
        unstow_repo(data)
        @exchange.reply(data)
        monitor_git
        stow_repo(data)
        self_destruct
      end

      def monitor_exchange
        begin
          data = @exchange.dequeue("backend.cedar", timeout: 10)
        end while !data
        data
      end
    
      def unstow_repo(data)
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

      def monitor_git
        begin
          puts "MONITORING..."
          flag = File.exists? "#{WORK_DIR}/.tmp/exit"
          sleep 5
        end while !flag
      end

      def stow_repo(data)
        `bin/stow-repo #{WORK_DIR} "#{data[:metadata]["repo_put_url"]}"`
        `bin/post-logs #{WORK_DIR} "#{data[:push_api_url]}"`
      end

      def self_destruct
        Process.kill("TERM", $$)
      end
    end

    Log.instrument(self, :monitor_exchange)
    Log.instrument(self, :unstow_repo)
    Log.instrument(self, :monitor_git)
    Log.instrument(self, :stow_repo)
  end
end