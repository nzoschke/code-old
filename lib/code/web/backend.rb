require "sinatra"
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
    end
  end
end