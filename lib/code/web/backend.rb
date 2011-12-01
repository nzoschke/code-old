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

        puts `bin/unstow-repo #{$work_dir} "#{data[:repo_get_url]}" `

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