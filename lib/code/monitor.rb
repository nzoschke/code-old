module Code
  class Monitor
    attr_reader :num_processes, :processes

    def initialize
      @num_processes = ENV["NUM_PROCESSES"] || 5
      @processes = []
    end

    def start(cmd, env={})
      pid = (5000..6000).to_a.sample
      @processes << pid
      pid
    end
  end
end