require "sinatra"
require "yaml"
require "./lib/code/models"

module Code
  module Web
    class PushAPI < Sinatra::Application
      include Code::Models
      helpers Helpers

      set :views, File.join(APP_DIR, "views")

      get "/" do
        @pushes = Push.order(:created_at.desc).limit(100)
        erb :pushes
      end

      post "/" do
        release = YAML.load_file params[:release][:tempfile]

        Push.create( 
          app_id:         params[:app_id],
          app_name:       params[:app_name],
          user_email:     params[:user_email],
          heroku_host:    params[:heroku_host],

          stack:          release["stack"],
          framework:      release["buildpack"],

          buildpack_url:  params[:buildpack_url],
          detect:         params[:detect][:tempfile].read,
          compile:        params[:compile][:tempfile].read,
          release:        params[:release][:tempfile].read,
          debug:          params[:debug][:tempfile].read,
          exit_status:    params[:exit_status]
        )
        "ok"
      end
    end
  end
end