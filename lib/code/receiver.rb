require "yaml"
require "./lib/code"

module Code
  class Receiver
    instrumentable do
      attr_reader :data, :exchange
    
      def initialize(opts={})
        opts.reverse_merge!(data: {}, server_pid: nil)

        @data       = opts[:data]
        @exchange   = Exchange.new
        @server_pid = opts[:server_pid]
      end

      def start!
        write_ssh_config

        begin
          monitor_server
          monitor_queue
        end while @data.empty?

        unstow_repo
        reply_exchange
        monitor_git && stow_repo
        self_destruct
      end

      def write_ssh_config
        ssh_dir = "#{ENV["HOME"]}/.ssh"
        return if File.exist? ssh_dir

        bash  "mkdir -p #{ssh_dir}"
        write "#{ssh_dir}/config", "StrictHostKeyChecking=no"
        write "#{ssh_dir}/id_rsa", ENV["SSH_PRIVATE_KEY"]
      end

      def monitor_queue
        if d = exchange.dequeue("backend.cedar", timeout: 30)
          age = Time.now - d[:created_at]
          Log.log(monitor_queue: true, empty: "false", exchange_key: d[:exchange_key], age: age)
          if age < 10
            exchange.reply(d)
            return @data = d
          end
        end
        
        Log.log(monitor_queue: true, empty: "true")
      end

      def monitor_server
        # abort if server process is no longer running
        return unless @server_pid

        begin
          Process.getpgid @server_pid
        rescue Errno::ESRCH
          Log.log(test_server: true, pid: @server_pid, empty: "true")
          exit(1)
        end
      end

      def unstow_repo
        bash "bin/unstow-repo #{WORK_DIR} '#{data[:metadata]["repo_get_url"]}'"

        # persist metadata and env to the disk
        File.open("#{WORK_DIR}/.tmp/metadata.yml", "w") { |f| f.write YAML.dump data[:metadata] }

        envdir = "#{WORK_DIR}/.tmp/env"
        Dir.mkdir(envdir)
        data[:metadata]["env"].merge(
          "LOG_TOKEN" => ENV["LOG_TOKEN"], 
          "PATH"      => ENV["PATH"]
        ).each do |k,v|
          File.open("#{envdir}/#{k}", "w") { |f| f.write v }
        end
      end

      def reply_exchange
        d = exchange.dequeue(data[:exchange_key], timeout: 10)
        d ? exchange.reply(d) : self_destruct # if frontend disappeared, destroy repo
      end

      def monitor_git
        started = Time.now
        loop do
          age = Time.now - started
          info_start      = File.exists? "#{WORK_DIR}/.tmp/info_start"
          rpc_start       = File.exists? "#{WORK_DIR}/.tmp/rpc_start"
          rpc_exit        = File.exists? "#{WORK_DIR}/.tmp/rpc_exit"
          compile_start   = File.exists? "#{WORK_DIR}/.tmp/start"
          compile_exit    = File.exists? "#{WORK_DIR}/.tmp/exit"
          exit_status     = File.read("#{WORK_DIR}/.tmp/exit").strip.to_i rescue -1

          Log.log(monitor_git: true, age: age, info_start: info_start.to_s, rpc_start: rpc_start.to_s, compile_start: compile_start.to_s, compile_exit: compile_exit.to_s, rpc_exit: rpc_exit.to_s)

          return true  if rpc_exit && exit_status == 0  # successful compile, stow repo
          return false if rpc_exit                      # fetch or unsuccessful compile, throw away
          return false if !rpc_start && age > 30        # noop, throw away
          sleep 5
        end
      end

      def stow_repo
        bash "bin/stow-repo #{WORK_DIR} '#{data[:metadata]["repo_put_url"]}'"
      end

      def self_destruct
        bash "bin/post-logs #{WORK_DIR} '#{data[:push_api_url]}'"
        Process.kill("TERM", $$)
      end

      def bash(command)
        `#{command}`
      end

      def write(path, contents)
        File.open(path, "w") { |f| f.write(contents) }
      end
    end

    Log.instrument(self, :monitor_queue,  eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :unstow_repo,    eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :reply_exchange, eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :monitor_git,    eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :stow_repo,      eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :self_destruct,  eval: "{hostname: exchange.hostname}")
    Log.instrument(self, :bash,           eval: "{command:  args[0]}")
    Log.instrument(self, :write,          eval: "{path:     args[0]}")
  end
end