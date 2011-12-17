require "redis"
require "sinatra"
require "yaml"
require "./lib/code/models"

module Code
  module Web
    class PushAPI < Sinatra::Application
      include Code::Models
      helpers Helpers

      set :views, File.join(APP_DIR, "views")

      use Rack::Session::Cookie, :secret => ENV["SECURE_KEY"], :expire_after => (60 * 60 * 24 * 7)

      get "/" do
        redirect("/auth/google") if !session["authorized"]

        @pushes = Push.order(:created_at.desc).limit(100)
        erb :pushes
      end

      post "/" do
        metadata = YAML.load_file params[:metadata][:tempfile]
        detect   = params[:detect][:tempfile].read

        app_name, host = metadata["url"].split(".", 2)

        Push.create( 
          app_id:         metadata["id"],
          app_name:       app_name,
          user_email:     metadata["user_email"].to_s,
          heroku_host:    host,

          stack:          metadata["stack"],
          buildpack_url:  metadata["env"]["BUILDPACK_URL"],

          framework:      detect,
          detect:         detect,
          compile:        params[:compile][:tempfile].read,
          release:        params[:release][:tempfile].read,
          debug:          params[:debug][:tempfile].read,
          exit:           params[:exit][:tempfile].read
        )
        "ok"
      end
    end
  end
end