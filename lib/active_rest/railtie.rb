require "active_rest"
require "rails"
require "active_model/railtie"
require "action_controller/railtie"

module ActiveRest
  class Railtie < Rails::Railtie
    config.app_generators.orm :active_rest, :migration => false

    console do
      ActiveRest::Base # Prevent load order shenanigans via goofy console use
    end

    initializer "active_rest.initialize_config" do |app|
      ActiveSupport.on_load(:after_initialize) do
        Config.config = app.config.database_configuration[Rails.env || "development"]
        ActiveRest::Config::LOGGER = ::Rails.logger
      end
    end

    rake_tasks do
      load 'tasks/db.rake'
    end
  end
end
