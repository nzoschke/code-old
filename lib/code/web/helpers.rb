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
    end
  end
end