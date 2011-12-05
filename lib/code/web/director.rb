require "sinatra"

module Code
  module Web
    class Director < Sinatra::Application
      helpers Helpers

      set :public_folder, File.join(APP_DIR, "public")

      get "/:app_name.git/info/refs" do
        metadata = new_release!(params[:app_name])

        begin
          # find a lively receiver
          d = exchange.exchange("backend.cedar", {
            app_name:     params[:app_name],
            push_api_url: "http://#{exchange.hostname}/pushes",
            metadata:     metadata,
          }, name: params[:app_name], timeout: 10)
        rescue Code::Exchange::ReplyError => e
          throw(:halt, [504, "Receiver not available"])
        end

        # block for receiver to unstow
        exchange.exchange(d[:exchange_key], {}, timeout: 120)
        forward! d[:hostname]
      end

      post "/:app_name.git/git-receive-pack" do
        core_auth!(params[:app_name])

        d = exchange.get(params[:app_name])
        forward! d[:hostname]
      end

      post "/:app_name.git/git-upload-pack" do
        core_auth!(params[:app_name])

        d = exchange.get(params[:app_name])
        forward! d[:hostname]
      end
    end
  end
end