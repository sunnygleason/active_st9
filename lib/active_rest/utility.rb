require 'shellwords'
require 'pathname'
require 'tempfile'

module ActiveRest
  module Utility
    class NukeFailedError < StandardError; end
    def self.nuke!(preserve_schema=true)
      path = '/1.0/nuke'
      path += '?preserveSchema=true' if preserve_schema

      response = Connection.http_post(path, nil)

      if response.status == 403
        raise NukeFailedError, 'This instance of ST9 has nuke disabled!'
      elsif response.status != 200
        raise NukeFailedError, "Unable to nuke ST9 due to unknown error (#{response.status})"
      end
    end

    def self.ping
      response = ActiveRest::Connection.ping
      response.nil? ? false : response.body.strip == 'OK'
    # Under JRuby: java.net.ConnectException
    rescue Exception
      false
    end

    def self.curl(method, path, data = nil, headers = {}, opts = {})
      cmd = []
      cmd << `which curl`.strip
      cmd << '-vv'
      cmd << "-X #{method.to_s.upcase}"

      headers = ActiveRest::Connection::DEFAULT_HTTP_HEADERS.merge(headers).merge('Accepts' => 'application/json')
      headers.each { |k,v| cmd << "-H \"#{Shellwords.escape(k)}: #{Shellwords.escape(v)}\"" }

      cmd <<
        case data
        when Pathname then "--data-binary @#{data.expand_path}"
        when String   then "--data #{Shellwords.escape(data)}"
        end

      cmd << URI.join(ActiveRest::Connection.http_client.base_url, path).to_s

      opts[:out] ||=
        begin
          f = Tempfile.new('out')
          f.close
          f.path.to_s
        end
      opts[:err] ||=
        begin
          f = Tempfile.new('err')
          f.close
          f.path.to_s
        end
      opts[:out] = opts[:out].expand_path.to_s if opts[:out].respond_to?(:expand_path)
      opts[:err] = opts[:err].expand_path.to_s if opts[:err].respond_to?(:expand_path)

      cmd << "> #{opts[:out]}"
      cmd << "2> #{opts[:err]}"

      cmd = cmd.compact.join(" ")

      if ENV['VERBOSE'] == 'true'
        if ENV['DEBUG'] == 'true'
          puts
          puts "======================================================================"
          puts "#{method.to_s.upcase.rjust(4)} #{path}"
          puts "----------------------------- COMMAND --------------------------------"
          puts "#{cmd}"
        else
          print "#{method.to_s.upcase.rjust(4)} #{path} -> "
        end
      end

      system(cmd)

      err = File.read(opts[:err])
      pattern = /\< HTTP\/1\.1 ([0-9]{3}) /
      status_line = err.split(/\n+/).grep(pattern).last
      status = status_line && status_line.match(pattern)[1].strip

      if ENV['VERBOSE'] == 'true'
        puts status

        if ENV['DEBUG'] == 'true' || status.to_i < 200 || status.to_i >= 300
          puts "------------------------------- STDERR -------------------------------"
          puts err
          puts "------------------------------- STDOUT -------------------------------"
          puts File.read(opts[:out])
        end
      end

      Struct.new(:status, :body).new(
        status.to_i,
        Pathname.new(opts[:out].to_s)
      )

    ensure
      Pathname.new(opts[:err].to_s).unlink rescue nil
    end
  end
end
