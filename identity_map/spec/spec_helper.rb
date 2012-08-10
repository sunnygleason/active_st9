require 'bundler/setup'
require "active_rest/identity_map"
require "support/model"

ActiveRest::Config.config = {"host" => "localhost", "port" => "7331", "allow_cascades" => true}
ActiveRest::Config::LOGGER = ::Logger.new(STDOUT)
ActiveRest::Config::LOGGER.level = Logger::INFO

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before :each do
    ActiveRest::IdentityMap.clear
    ActiveRest::Utility.nuke!(false)
    Model.post_schema
  end
end
