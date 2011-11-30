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

    get "/:app_name.git/info/refs" do
      d = exchange.exchange("backend.cedar", {app_name: params[:app_name]})
      redirect "https://#{d[:hostname]}/code.git/info/refs", 302
    end

    post "/:app_name.git/git-receive-pack" do
      d = exchange.get(params[:app_name])
      redirect "https://#{d[:hostname]}/code.git/git-receive-pack", 302
    end
  end
end