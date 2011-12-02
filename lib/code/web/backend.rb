require "sinatra"
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

        # write the build env to disk
        File.open("#{$work_dir}/.log/build_env", "w") do |f|
          data[:env].merge("PATH" => ENV["PATH"]).each do |k,v|
            v = v.gsub(/'/, "\\\\'")  # escape any single quotes with backslash
            f.write("#{k}=$'#{v}'\n") # use bash $'...' ANSI-C quoting
          end
        end

        ex.reply(data)

        begin
          puts "MONITORING..."
          flag = File.exists? "#{$work_dir}/.log/finished"
          sleep 5
        end while !flag
        Process.kill("TERM", $$)
      end
    end
  end
end