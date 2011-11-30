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

    def self.monitor_exchange
      ex = Exchange.new
      begin
        puts "DEQUEING..."
        data = ex.dequeue("backend.cedar", timeout: 10)
      end while !data

      puts data.inspect
      puts <<`EOF`
        set -x
        TMP_DIR=#{$root}/tmp
        rm -rf $TMP_DIR
        mkdir -p $TMP_DIR
        git init --bare $TMP_DIR/code.git
EOF

      ex.reply(data)
    end
  end
end