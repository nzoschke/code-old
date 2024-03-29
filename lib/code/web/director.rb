require "oa-openid"
require "openid_redis_store"
require "sinatra"

module Code
  module Web
    class Director < Sinatra::Application
      helpers Helpers

      set :public_folder, File.join(APP_DIR, "public")

      use Rack::Session::Cookie, :secret => ENV["SECURE_KEY"], :expire_after => (60 * 60 * 24 * 7)
      use OmniAuth::Strategies::GoogleApps,
        OpenID::Store::Redis.new(Redis.connect(:url => ENV["REDIS_URL"])),
        :name   => "google",
        :domain => "heroku.com"

      get "/" do
        "Hello world"
      end

      post "/auth/google/callback" do
        session["authorized"] = true
        redirect(session["from"] || "/")
      end

      get "/:app_name.git/info/refs" do
        metadata = new_release!(params[:app_name])
        major_stack = metadata["stack"].split("-")[0]

        begin
          # find a lively receiver
          d = exchange.exchange("backend.#{major_stack}", {
            app_name:     params[:app_name],
            push_api_url: "https://#{env["HTTP_HOST"]}/pushes",
            metadata:     metadata,
            action:       "receive"
          }, name: params[:app_name], timeout: 10)
        rescue Code::Exchange::ReplyError => e
          throw(:halt, [504, "Receiver not available"])
        end

        # block for receiver to unstow
        exchange.exchange(d[:exchange_key], {}, timeout: 120)
        proxy! d[:hostname]
      end

      post "/:app_name.git/git-receive-pack" do
        core_auth!(params[:app_name])

        d = exchange.get(params[:app_name])
        proxy! d[:hostname]
      end

      post "/:app_name.git/git-upload-pack" do
        core_auth!(params[:app_name])

        d = exchange.get(params[:app_name])
        proxy! d[:hostname]
      end

      post "/compiles" do
        api_auth!

        metadata = JSON.load(request.body.read)

        app_name    = metadata["url"].split(".")[0]
        major_stack = metadata["stack"].split("-")[0]

        begin
          # send a "compile" message to lively receiver
          d = exchange.exchange("backend.#{major_stack}", {
            app_name:     app_name,
            push_api_url: "https://#{env["HTTP_HOST"]}/pushes",
            metadata:     metadata,
            action:       "compile"
          }, name: app_name, timeout: 10)
        rescue Code::Exchange::ReplyError => e
          throw(:halt, [504, "Receiver not available"])
        end

        "ok"
      end
    end
  end
end
