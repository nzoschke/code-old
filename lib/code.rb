STDERR.sync = STDOUT.sync = true

APP_DIR   ||= File.expand_path(File.join(__FILE__, "..", ".."))
WORK_DIR  ||= "/tmp/work"
SYSTEM    ||= `echo $(uname)-$(uname -m)`.strip # Darwin-x86_64, Linux-x86_64, etc.

# prepend vendored binaries to path
ENV["PATH"] = [
  "#{APP_DIR}/vendor/#{SYSTEM}/bin",
  "#{APP_DIR}/opt/slug-compiler/bin",
  ENV["PATH"]
].join(":") unless ENV["PATH"] =~ /#{SYSTEM}/

ENV["TZ"]   = "UTC"

require "./lib/log"
require "./lib/code/exchange"
require "./lib/code/models"
require "./lib/code/monitor"
require "./lib/code/receiver"
require "./lib/code/web"

class Hash
  def reverse_merge!(h)
    replace(h.merge(self))
  end
end