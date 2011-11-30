module Code
  class Monitor
    attr_reader :num_processes, :processes

    def initialize
      @num_processes = ENV["NUM_PROCESSES"] || 5
      @processes = []
    end
  end
end