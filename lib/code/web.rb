require "sinatra"
require "./lib/code"

module Code
  module Helpers
    def exchange
      @exchange ||= Code::Exchange.new
    end
  end

  class Web < Sinatra::Application
    helpers Helpers

    get "/:name.git/info/refs" do
      redirect "https://route.heroku.com:3333/code.git/info/refs", 302
    end

    post "/:name.git/git-receive-pack" do
      redirect "https://route.heroku.com:3333/code.git/git-receive-pack", 302
    end
  end
end