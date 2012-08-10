module ActiveRest
  # Inherit from ActiveRest::Base to gain rudimentary ActiveModel-style functionality for RESTful objects.
  # Currently supported are new, create, update, save, has_one relationships (see relationships/has_one)
  # ActiveModel Validators, ActiveModel Callbacks, ActiveModel Conversions, and ActiveModel Naming.

  class Base
    extend ActiveRest::InheritableAttributes

    def self.inherited(subclass)
      # Go up the inheritance chain if we are not descending directly from ActiveRest::Base.
      subclass.instance_variable_set(
        :@base_class,
        (subclass.superclass == ActiveRest::Base ?
          subclass :
          subclass.ancestors.find { |m| m.is_a?(Class) && m.superclass == ActiveRest::Base }
        )
      )
      subclass.instance_variable_set(:@type, subclass.entity_name)
      subclass.instance_variable_set(
        :@inherited,
        (subclass.instance_variable_get(:@base_class).entity_name != subclass.instance_variable_get(:@type))
      )
      super
    end

    def self.alias_attribute(new_name, old_name)
      alias_method new_name, old_name
      alias_method "#{new_name}=", "#{old_name}="
    end

    module InstanceMethods
      attr_reader :db_id
      attr_reader :version

      def initialize(args_hash = {})
        @is_new = true
        update(args_hash)
      end

      def update(args_hash)
        args_hash.each do |a, v|
          self.send("#{a}=", v)
        end
      end

      def update_attributes(args_hash)
        update(args_hash)
        self.save
      end

      def update_attributes!(args_hash)
        update(args_hash)
        self.save!
      end

      def id
        return nil if @db_id.nil?
        @db_id.split(":").last
      end

      def hash
        persisted? ? db_id.hash : super
      end

      def eql?(v)
        v.equal?(self) ||
        (v.instance_of?(self.class) && v.persisted? && v.db_id == self.db_id)
      end

      def ==(v)
        eql?(v)
      end

    protected

      def update_raw(args_hash)
        args_hash.each do |a, v|
          if a == "id" || a == "version"
            self.send("#{a}=", v)
          else
            self.send("#{a}_raw=", v) if self.respond_to?("#{a}_raw=")
          end
        end
      end
    end

    class << self # class methods
      def create(args = {}, &block)
        obj = new(args)
        yield obj if block
        obj.save
        obj
      end

      def create!(args = {}, &block)
        obj = new(args)
        yield obj if block
        obj.save!
        obj
      end

      # Provides case equality for proxy objects
      def ===(other)
        other.is_a?(self)
      end
    end

    Base.class_eval do
      include ActiveModel::Validations
      include ActiveModel::Naming
      include ActiveModel::Conversion

      include ActiveRest::Base::InstanceMethods
      include ActiveModel::Dirty
      include ActiveRest::Persistence
      extend ActiveRest::Attributes
      include ActiveRest::Config
      include ActiveRest::Relations::HasOne
      include ActiveRest::Relations::HasMany
      include ActiveRest::Callbacks
      include ActiveRest::Counters
      include ActiveRest::Indexes
      include ActiveRest::Fulltexts
      include ActiveRest::Enum
      include ActiveRest::Schema
      include ActiveRest::StaticAttributes
      include ActiveRest::Query
      include ActiveRest::JsonSerializer
      include ActiveRest::Utility
      include ActiveRest::Reloadable
      include ActiveRest::Validations
    end

  protected

    def id=(val) # id is a magic field (!!!) in response JSON (yeah, we have to have at least one).
      @db_id = val
    end

    def version=(val) # version is a magic field (!!!) in response JSON (yeah, we know).
      @version = val
    end
  end
end
