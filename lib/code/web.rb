require "sinatra"
require "./lib/code"

module Code
  class Web < Sinatra::Application
    helpers do
      def exchange
        @exchange ||= Code::Exchange.new
      end
    end

    get "/:name.git/info/refs" do
      redirect "/foo", 302
    end

    post "/:name.git/git-receive-pack" do
      redirect "/foo", 302
    end
  end
end