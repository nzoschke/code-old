require "sinatra"

module Code
  module Web
    class Push < Sinatra::Application
      helpers Helpers

      post "/" do
        "ok"
      end
    end
  end
end