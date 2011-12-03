require "yaml"
require "./lib/code"

module Code
  class Receiver
    instrumentable do
      def monitor_exchange
        ex = Exchange.new # TODO: use Helpers
        begin
          data = ex.dequeue("backend.cedar", timeout: 10)
        end while !data

        `bin/unstow-repo #{WORK_DIR} "#{data[:metadata]["repo_get_url"]}"`

        # persist metadata and env to the disk
        File.open("#{WORK_DIR}/.tmp/metadata.yml", "w") { |f| f.write YAML.dump data[:metadata] }
        File.open("#{WORK_DIR}/.tmp/build_env", "w") do |f|
          data[:metadata]["env"].merge("PATH" => ENV["PATH"]).each do |k,v|
            v = v.gsub(/'/, "\\\\'")  # escape any single quotes with backslash
            f.write("#{k}=$'#{v}'\n") # use bash $'...' ANSI-C quoting
          end
        end

        ex.reply(data)

        begin
          puts "MONITORING..."
          flag = File.exists? "#{WORK_DIR}/.tmp/exit"
          sleep 5
        end while !flag

        `bin/stow-repo #{WORK_DIR} "#{data[:metadata]["repo_put_url"]}"`
        `bin/post-logs #{WORK_DIR} "#{data[:push_api_url]}"`

        Process.kill("TERM", $$)
      end
    end
  end
end