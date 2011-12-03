timeout(1800) # give git 30 minutes to do its RPC calls
worker_processes(1)

Thread.new do
  begin
    require "./lib/code"
    Code::Receiver.new
  rescue => e
    puts e.message
    puts e.backtrace
  end
end