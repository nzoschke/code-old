require "sinatra"

module Code
  module Web
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