require "sinatra"
require "./lib/code"

module Code
  class Web < Sinatra::Application
    helpers do
      def exchange
        @exchange ||= Code::Exchange.new
      end
    end

    get "/" do
      "hello world"
    end

    get "/:name.git/info/refs" do
    end

    post "/:name.git/git-receive-pack" do
    end
  end
end