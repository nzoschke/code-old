require "./lib/code/backend"
require "./lib/code/exchange"
require "./lib/code/web"

class Hash
  def reverse_merge!(h)
    replace(h.merge(self))
  end
end