module ActiveRest
  module
    IdentityMap
    class Railtie < Rails::Railtie
      initializer "active_rest.identity_map.initializer" do |app|
        app.middleware.use ActiveRest::IdentityMap::ClearMiddleware
      end
    end
  end
end
