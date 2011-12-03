require "sinatra"
require "yaml"
require "./lib/code"
require "./lib/git_http"

$work_dir = "/app"

module Code
  module Web
    class Backend < Sinatra::Application

      GIT = GitHttp::App.new({
        :project_root => "#{$work_dir}",
        :upload_pack  => true,
        :receive_pack => true,
      })

      def call(env)
        GIT.call(env)
      end

      def self.monitor_exchange
        ex = Exchange.new # TODO: use Helpers
        begin
          puts "DEQUEING..."
          data = ex.dequeue("backend.cedar", timeout: 10)
        end while !data

        `bin/unstow-repo #{$work_dir} "#{data[:repo_get_url]}"`

        # persist metadata and env to the disk
        File.open("#{$work_dir}/.tmp/metadata.yml", "w") { |f| f.write YAML.dump data[:metadata] }
        File.open("#{$work_dir}/.tmp/build_env", "w") do |f|
          data[:metadata]["env"].merge("PATH" => ENV["PATH"]).each do |k,v|
            v = v.gsub(/'/, "\\\\'")  # escape any single quotes with backslash
            f.write("#{k}=$'#{v}'\n") # use bash $'...' ANSI-C quoting
          end
        end

        ex.reply(data)

        begin
          puts "MONITORING..."
          flag = File.exists? "#{$work_dir}/.tmp/exit"
          sleep 5
        end while !flag

        `bin/post-logs #{$work_dir} "#{data[:push_api_url]}"`
  
        Process.kill("TERM", $$)
      end
    end
  end
end