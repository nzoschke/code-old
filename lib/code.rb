ENV["TZ"] = "UTC"
APP_DIR = File.expand_path(File.join(__FILE__, "..", ".."))

require "./lib/code/exchange"
require "./lib/code/models"
require "./lib/code/monitor"
require "./lib/code/web"

class Hash
  def reverse_merge!(h)
    replace(h.merge(self))
  end
end