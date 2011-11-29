require "./lib/code/exchange"

class Hash
  def reverse_merge!(h)
    replace(h.merge(self))
  end
end