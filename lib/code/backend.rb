require "sinatra"
require "./lib/code"
require "./lib/git_http"

$root = File.expand_path(File.join(__FILE__, "..", "..", ".."))

module Code
  class Backend < Sinatra::Application

    GIT = GitHttp::App.new({
      :project_root => "#{$root}/tmp",
      :upload_pack  => true,
      :receive_pack => true,
    })

    def call(env)
      GIT.call(env)
    end
  end
end