require "sinatra"
require "./lib/code/models"

module Code
  module Web
    class PushAPI < Sinatra::Application
      include Code::Models
      helpers Helpers

      post "/" do
        "ok"
      end
    end
  end
end