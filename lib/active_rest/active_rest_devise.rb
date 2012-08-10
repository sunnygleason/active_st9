module Devise
  module Orm
    module ActiveRecord
      module Schema
        include Devise::Schema

        Devise.apply_schema
        # Tell how to apply schema methods.
        def apply_devise_schema(name, type, options={})
          eval "#{type.entity_name}, #{name}, #{options.to_s}"
        end
      end
    end
  end
end

#Devise::RegistrationsController

#Devise::RegistrationsController.module_eval do
#  alias_method :old_authenticate_scope!, :authenticate_scope!
#  def authenticate_scope!
#      send(:"authenticate_#{resource_name}!", true)
#      self.resource = resource_class.find(send(:"current_#{resource_name}").to_key).first
#  end
#end

ActiveRest::Base.extend Devise::Models
ActiveRest::Base.extend Devise::Orm::ActiveRecord::Schema
