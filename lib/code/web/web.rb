require "sinatra"
require "./lib/code"

module Code
  module Web
    module Helpers
      def exchange
        @exchange ||= Code::Exchange.new
      end

      def forward!(hostname)
        url  = "http://#{hostname}"
        url += env["PATH_INFO"]
        url += "?" + env["QUERY_STRING"] unless env["QUERY_STRING"].empty?
        redirect url, 302
      end
    end

    class Web < Sinatra::Application
      helpers Helpers

      get "/:app_name.git/info/refs" do
        d = exchange.exchange("backend.cedar", {app_name: params[:app_name]}, name: params[:app_name])
        forward! d[:hostname]
      end

      post "/:app_name.git/git-receive-pack" do
        d = exchange.get(params[:app_name])
        forward! d[:hostname]
      end
    end
  end
end