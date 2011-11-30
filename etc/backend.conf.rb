timeout(1800) # give git 30 minutes to do its RPC calls
worker_processes(1)

Thread.new do
  begin
    require "./lib/code"
    Code::Backend.monitor_exchange
  rescue => e
    puts e.message
    puts e.backtrace
  end
end