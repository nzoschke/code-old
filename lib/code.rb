ENV["TZ"] = "UTC"

require "./lib/code/backend"
require "./lib/code/exchange"
require "./lib/code/monitor"
require "./lib/code/web"

class Hash
  def reverse_merge!(h)
    replace(h.merge(self))
  end
end

module Code
  def self.require_models
    require "./lib/code/models"
  end

  def self.reload_models
    require_models
    load "./lib/code/models.rb"
  end
end