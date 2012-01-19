require "json"
require "rack/streaming_proxy"
require "rest-client"

module Code
  module Web
    module Helpers
      def exchange
        @exchange ||= Code::Exchange.new
      end

      def proxy!(hostname)
        req  = Rack::Request.new(env)
        uri  = "#{env["rack.url_scheme"]}://#{hostname}"
        uri += env["PATH_INFO"]
        uri += "?" + env["QUERY_STRING"] unless env["QUERY_STRING"].empty?

        begin # only want to catch proxy errors, not app errors
          proxy = Rack::StreamingProxy::ProxyRequest.new(req, uri)
          [proxy.status, proxy.headers, proxy]
        rescue => e
          msg = "Proxy error when proxying to #{uri}: #{e.class}: #{e.message}"
          env["rack.errors"].puts msg
          env["rack.errors"].puts e.backtrace.map { |l| "\t" + l }
          env["rack.errors"].flush
          raise StandardError, msg
        end
      end

      def forward!(hostname)
        url  = "#{env["rack.url_scheme"]}://#{hostname}"
        url += env["PATH_INFO"]
        url += "?" + env["QUERY_STRING"] unless env["QUERY_STRING"].empty?
        redirect url, 302
      end

      def auth!
        response["WWW-Authenticate"] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Unauthorized"])
      end

      def creds
        auth = Rack::Auth::Basic::Request.new(request.env)
        auth.provided? && auth.basic? ? auth.credentials : auth!
      end

      def heroku_get!(path)
        host = "api.heroku.com"
        if m = env["HTTP_HOST"].match(/(.*).code.heroku.com/)
          host = "api.#{m[1]}.herokudev.com"
        end
        resource = RestClient::Resource.new("https://#{host}", user: creds[0], password: creds[1])[path]

        # TODO: s = Log.start ; s.end
        start = Time.now
        Log.log(heroku_get: true, at: :start, resource: resource.to_s)

        begin
          resource.get(accept: :json) do |response, request, result, &block|
            Log.log(heroku_get: true, :at => :finish, elapsed: Time.now - start, :code => response.code)
            response.code == 200 ? JSON.parse(response) : response.return!(request, result, &block)
          end
        rescue RestClient::ResourceNotFound => e
          throw(:halt, [404, "Not Found"])
        rescue RestClient::Unauthorized => e
          auth!
        end
      end

      def core_auth!(app_name)
        heroku_get! "/apps/#{app_name}"
      end

      def new_release!(app_name)
        heroku_get! "/apps/#{app_name}/releases/new"
      end
    end
  end
end