require 'active_rest'
require 'orm_adapter'

class ActiveRest::Base
  extend OrmAdapter::ToAdapter

  class OrmAdapter < ::OrmAdapter::Base

    # Do not consider these to be part of the class list
    def self.except_classes
      @@except_classes ||= []
    end

    # Gets a list of the available models for this adapter
    def self.model_classes
      ## XXX SOMETHING EVIL LURKS HERE
      klasses = []
      ObjectSpace.each_object(Class) { |klass| klasses << klass if klass.superclass == ActiveRest::Base } # Avoid performing to_a on each_object which is an iter over an iter
      klasses
    end

    # Return list of column/property names
    def column_names
      klass.attributes.keys
    end

    # @see OrmAdapter::Base#get!
    def get!(id)
      klass.find(wrap_key(id))
    end

    # @see OrmAdapter::Base#get
    def get(id)
      klass.find(wrap_key(id))
    end

    # @see OrmAdapter::Base#find_first
    def find_first(options) ## XXX THIS DOES NOT IMPLEMENT THE REAL ORM ADAPTER API
      conditions, order = extract_conditions_and_order!(options)
      composite_condition(conditions).first # EVIL
    end

    # @see OrmAdapter::Base#find_all
    def find_all(options) ## XXX THIS DOES NOT IMPLEMENT THE REAL ORM ADAPTER API
      conditions, order = extract_conditions_and_order!(options)
      composite_condition(conditions)
    end

    # @see OrmAdapter::Base#create!
    def create!(attributes)
      klass.create!(attributes)
    end

    protected

    def composite_condition(conditions)
      conditions_finders = conditions.map do |key, value|
        klass.find_with_index(key.to_s, value) # XXX ASSUMES INDEX CALLED "key"
      end
      condition = conditions_finders[0]
      conditions_finders.each_with_index do |c_f, index|
        next if index == 0
        condition = condition & c_f
      end
      condition
    end

  end
end
