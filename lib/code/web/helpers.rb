require "json"
require "rest-client"

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

      def auth_creds
        auth = Rack::Auth::Basic::Request.new(env)
        auth.provided? && auth.basic? ? auth.credentials : [nil, nil]
      end

      def heroku
        RestClient::Resource.new("https://api.heroku.com", user: auth_creds[0], password: auth_creds[1])
      end

      def new_release!(app_name)
        begin
          JSON.parse heroku["/apps/#{app_name}/releases/new"].get(accept: :json)
        rescue RestClient::Unauthorized => e
          throw(:halt, [401, "Unauthorized"])
        end
      end
    end
  end
end