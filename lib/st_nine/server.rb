require 'tempfile'
require 'escape'

module StNine
  class Server
    attr_accessor :port
    attr_writer :out_log, :pid_file, :db_file, :db_type, :classpath, :data_dir, :log_dir, :pid_dir, :install_dir, :allow_nuke

    def remove_pid
      if File.exist?(pid_path)
        STDERR.puts "Removed stale PID file at #{pid_path}"
        FileUtils.rm(pid_path)
      end
    end

    def background
      if File.exist?(pid_path)
        old_pid = IO.read(pid_path).to_i
        begin
          Process.kill(0, old_pid)
          raise RuntimeError, "Server is already running with PID #{old_pid}"
        rescue Errno::ESRCH
          remove_pid
        end
      end

      if defined?(JRUBY_VERSION)
        require 'st_nine/posix_spawn'
        fas = PosixSpawn::FileActions.new
        PosixSpawn.file_actions_init(fas.pointer)
        PosixSpawn.file_actions_add_close(fas, STDIN.fileno)
        PosixSpawn.file_actions_add_open(fas, STDOUT.fileno, out_path, File::WRONLY|File::CREAT|File::APPEND)
        PosixSpawn.file_actions_add_dup(fas, STDOUT.fileno, STDERR.fileno)
        pid = PosixSpawn.spawnp 'java', fas, *args
        PosixSpawn.file_actions_destroy(fas.pointer)
        FileUtils.mkdir_p(File.dirname(pid_path))
        File.open(pid_path, 'w') { |f| f << pid }
        pid
      else
        fork do
          pid = fork do
            Process.setsid
            STDIN.reopen('/dev/null')
            STDOUT.reopen(out_path, 'a')
            STDERR.reopen(STDOUT)
            exec(command)
          end
          FileUtils.mkdir_p(File.dirname(pid_path))
          File.open(pid_path, 'w') { |f| f << pid }
        end
        pid
      end
    end

    def pid_running?(pid)
      !!`ps -p #{pid} 2> /dev/null`.match(pid.to_s)
    end

    def stop
      if File.exist?(pid_path)
        old_pid = IO.read(pid_path).to_i
        begin
          Process.kill(9, old_pid)
          while pid_running?(old_pid) do
            yield if block_given?
            sleep 1
          end
        rescue Errno::ESRCH
          STDERR.puts("Server with PID #{old_pid} is not running")
        end
        FileUtils.rm(pid_path)
      end
    end

    def get_pid
      if File.exist?(pid_path)
        IO.read(pid_path).to_i
      else
        false
      end
    end

    def run
      `#{command}`
    end

    def command
      Escape.shell_command(args.unshift('java'))
    end

    def args
      args = []
      args << '-Xmx2048m'
      args << '-Xms2048m'
      args << '-XX:+UseConcMarkSweepGC'
      args << '-XX:+CMSIncrementalMode'
      args << '-XX:+PrintGCDetails'
      args << '-XX:+PrintGCTimeStamps'
      args << '-cp' << classpath
      args << db_url_arg unless db_path.empty?
      args << "-Dlog.dir=#{log_dir}"
      args << "-Dhttp.port=#{port}" if port
      args << "-Dnuke.allowed=#{allow_nuke}"
      args << "-Dst9.storageModule=com.g414.st9.proto.service.store.#{db_storage_driver}"
      args << 'com.g414.st9.proto.service.Main'
    end

    def classpath
      @classpath || File.expand_path(File.join(install_dir, 'lib', '*'))
    end

    def db_file
      @db_file || 'st9.db'
    end

    def db_path
      case db_type
      when :sqlite then 'jdbc:sqlite:' + File.expand_path(File.join(data_dir, db_file))
      else ''
      end
    end

    def db_url_arg
      "-Djdbc.url=#{db_path}"
    end

    def db_type
      (@db_type || :sqlite).to_sym
    end

    def db_storage_driver
      case db_type
        when :sqlite then 'SqliteKeyValueStorage$SqliteKeyValueStorageModule'
        when :h2 then 'H2KeyValueStorage$H2KeyValueStorageModule'
        else raise 'Unknown db_type! Use :sqlite or :h2'
      end
    end

    def out_log
      @out_log || 'out.log'
    end

    def out_path
      File.expand_path(File.join(log_dir, out_log))
    end

    def pid_file
      @pid_file || 'st9.pid'
    end

    def pid_path
      File.expand_path(File.join(pid_dir || FileUtils.pwd, pid_file))
    end

    def allow_nuke
      !!@allow_nuke
    end

    def root_dir
      return File.expand_path(File.join(::Rails.root, 'st9')) if defined?(Rails)
      ENV['ST9_DIR'] || File.expand_path("../../../st9", __FILE__)
    end

    def install_dir
      File.expand_path(@install_dir || root_dir)
    end

    def log_dir
      File.expand_path(@log_dir || File.join(install_dir, 'log'))
    end

    def out_dir
      File.expand_path(@log_dir || log_dir)
    end

    def data_dir
      File.expand_path(@data_dir || File.join(install_dir, 'data'))
    end

    def pid_dir
      File.expand_path(@pid_dir || install_dir)
    end
  end
end
