module Code
  class Monitor
    def initialize
    end

    def num_processes
      ENV["NUM_PROCESSES"] || 5
    end
  end
end