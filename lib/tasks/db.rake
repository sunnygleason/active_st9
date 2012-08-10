require "active_rest"
require 'active_rest/utility'
require 'pathname'

namespace :db do
  desc 'Install and start the database (if needed), and load a fresh schema (options: VERBOSE=false, DEBUG=true)'
  task :setup => :environment do
    ENV['VERBOSE'] = 'true' unless ENV['VERBOSE'].present?

    Rake::Task['db:install'].invoke
    Rake::Task['db:start'].invoke
    Rake::Task['db:migrate'].invoke
  end

  #
  # Schema
  #

  desc 'Load the schema for classes inheriting from ActiveRest::Base (options: MODELS=MyModel, VERBOSE=false, DEBUG=true)'
  task :schema => :environment do
    ENV['VERBOSE'] = 'true' unless ENV['VERBOSE'].present?

    models =
      ENV['MODELS'].presence &&
      ENV['MODELS'].split(',').map(&:classify).map(&:constantize)

    schema_update "post", models
  end

  desc 'Migrates the schema for classes inheriting from ActiveRest::Base (options: MODELS=MyModel, VERBOSE=false, DEBUG=true)'
  task :migrate => :environment do
    ENV['VERBOSE'] = 'true' unless ENV['VERBOSE'].present?

    models =
      ENV['MODELS'].presence &&
      ENV['MODELS'].split(',').map(&:classify).map(&:constantize)

    schema_update "put", models
  end

  desc 'Nuke and load the schema.'
  task :reset => [:nuke, :schema]

  desc 'Loads schema and data from db/{environment}.json (FILE=dump.json, VERBOSE=false, DEBUG=true)'
  task :load => :environment do
    ENV['VERBOSE'] = 'true' unless ENV['VERBOSE'].present?

    ActiveRest::Utility.curl(:post, "/1.0/x", Pathname.new(dumpfile_path))
  end

  desc 'Dumps schema and data to db/{environment}.json (FILE=dump.json, VERBOSE=false, DEBUG=true)'
  task :dump => :environment do
    ENV['VERBOSE'] = 'true' unless ENV['VERBOSE'].present?

    ActiveRest::Utility.curl(:get, "/1.0/x", nil, {}, { :out => Pathname.new(dumpfile_path) })
  end

  desc 'Destroys all schema *and* data'
  task :nuke => :environment do
    ActiveRest::Utility.nuke!(false)
  end

  desc 'Destroys only the data, leaves the schema'
  task :truncate => :environment do
    ActiveRest::Utility.nuke!(true)
  end

  #
  # Install
  #

  desc 'Downloads and install ST9'
  task :install => :environment do
    require 'st_nine/installer'
    installer = StNine::Installer.new
    yml = YAML::load_file(config_path) || {}
    yml = yml[environment] if yml.has_key?(environment)
    StNine::Installer.
      public_instance_methods(false).
      select { |m| m.to_s.include?('=') }.
      map { |m| m.to_s.gsub('=', '') }.
      each do |attr|
        installer.send(attr + '=', yml[attr]) if yml.has_key?(attr)
      end
    installer.install
  end

  #
  # Start/Stop
  #

  desc 'Starts an instance of ST9 in the background'
  task :start => :environment do
    server = create_configure_st9_server_instance

    if server.get_pid && ActiveRest::Utility.ping
      puts "ST9 is already running"
    else
      server.remove_pid

      print 'Starting ST9'
      pid = server.background

      # wait until it pings true
      ping_result = false
      15.times do
        print '.'
        break if ping_result = ActiveRest::Utility.ping
        sleep 1
      end

      if ping_result
        puts " started with PID #{pid}"
      else
        puts " error, could not start"
      end
    end
  end

  desc 'Stops a previously backgrounded ST9'
  task :stop => :environment do
    server = create_configure_st9_server_instance

    if server.get_pid
      print 'Stopping ST9'

      # wait until it pings true (may have just started)
      ping_result = false
      15.times do
        print '.'
        break if ping_result = ActiveRest::Utility.ping
        sleep 1
      end

      # now stop
      server.stop { print '.' }

      # wait until it pings false (may have just started)
      ping_result = true
      15.times do
        print '.'
        break unless ping_result = ActiveRest::Utility.ping
        sleep 1
      end

      # check it pings false
      if ping_result
        puts " unable to stop"
      else
        puts " stopped"
      end
    else
      puts "ST9 is not running (no PID file)"
    end
  end

  desc 'Restart ST9'
  task :restart => [:stop, :start]
end

unless defined?(Rails)
  task :environment do
    ActiveRest::Config::LOGGER = ::Logger.new(STDOUT)
    ActiveRest::Config::LOGGER.level = Logger::INFO
    if File.exists?(config_path)
      yml = YAML::load_file(config_path)
      ActiveRest::Config.config = yml
    else
      raise "St9 configuration not found in #{config_path}"
    end
  end
end

def environment
  return ::Rails.env if defined?(Rails)
  ENV['ACTIVEREST_ENV'] || ''
end

def root_path
  return ::Rails.root if defined?(Rails)
  File.expand_path("../../..", __FILE__)
end

def dumpfile_path
  ENV['FILE'] ||
    environment.present? ?
    File.expand_path(File.join(root_path, "db/#{environment}.json")) :
    'dump.json'
end

def config_path
  File.join(root_path, "config", "database.yml")
end

def create_configure_st9_server_instance
  require 'st_nine/server'
  server = StNine::Server.new
  yml = YAML::load_file(config_path) || {}
  yml = yml[environment] if yml.has_key?(environment)
  StNine::Server.
    public_instance_methods(false).
    select { |m| m.to_s.include?('=') }.
    map { |m| m.to_s.gsub('=', '') }.
    each do |attr|
      server.send(attr + '=', yml[attr]) if yml.has_key?(attr)
    end
  server.port = yml['port'] if yml.has_key?('port')
  server
end

def schema_update(type, models = nil)
  if defined?(Rails)
    # load all the models
    model_path = Rails.root.join("app/models")
    # XXX temporary workaround dependent load order
    10.times { Dir[model_path.join("**/*.rb")].each { |f| require f rescue nil } }
  end

  # collect from object space
  models ||= ObjectSpace.each_object(Class).select { |o| o < ActiveRest::Base }

  # now update in order
  models.sort_by(&:name).each { |m| m.send("#{type}_schema") }
end

