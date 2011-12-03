require "sinatra"
require "./lib/git_http"

module Code
  module Web
    class Backend < Sinatra::Application

      GIT = GitHttp::App.new({
        :project_root => "#{WORK_DIR}",
        :upload_pack  => true,
        :receive_pack => true,
      })

      def call(env)
        GIT.call(env)
      end
    end
  end
end