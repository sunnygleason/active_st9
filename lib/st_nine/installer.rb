require 'tempfile'

module StNine
  class Installer
    attr_writer :maven_host, :install_dir, :version

    INSTALL_DIR =
      if defined?(Rails)
        File.expand_path(File.join(::Rails.root, 'st9'))
      else
        ENV['ST9_DIR'] || File.expand_path("../../../st9", __FILE__)
      end
    MAVEN_HOST = 'http://mvn.g414.com'
    VERSION = ENV['ST9_VERSION'] || '0.5.5'

    def install
      `which wget`
      raise RuntimeError, 'Wget is required' unless $?.exitstatus == 0
      puts "Installing version #{version} from #{maven_host} to #{install_dir}"
      FileUtils.mkdir_p(install_dir)
      FileUtils.cd(Dir.tmpdir) do
        `wget -c #{url}`
        raise RuntimeError, 'Download failed' unless $?.exitstatus == 0
        `tar zxf #{filename}`
        `rm -f #{install_dir}/*`
        `cp -f #{filename.gsub('-dist.tar.gz','')}/lib/* #{install_dir}`
      end
      puts 'Installation complete'
    end

    def url
      MAVEN_HOST + "/com/g414/st9/st9-proto-service/#{version}/" + filename
    end

    def filename
      "st9-proto-service-#{version}-dist.tar.gz"
    end

    def version
      @version || VERSION
    end

    def install_dir
      File.expand_path(File.join(@install_dir || INSTALL_DIR, 'lib'))
    end

    def maven_host
      @maven_host || MAVEN_HOST
    end
  end
end
