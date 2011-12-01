ENV["TZ"] = "UTC"

require "./lib/code/exchange"
require "./lib/code/models"
require "./lib/code/monitor"
require "./lib/code/web"

class Hash
  def reverse_merge!(h)
    replace(h.merge(self))
  end
end