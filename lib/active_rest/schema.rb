require 'active_support/time'

module ActiveRest
  module Schema
    extend ActiveSupport::Concern

    class BigString < String; end

    RUBY_TO_DB_TYPE = {
      TrueClass => :boolean,
      BigString => :utf8_text,
      Array => :array,
      Fixnum => :i32,
      Time => :utc_date_secs,
      String => :utf8_smallstring
    }

    # Reference returns itself as dereference is handled elsewhere. Fields of type "reference" are actually IDs.
    VALIDATE_DB_TYPE = {
      :enum => lambda { |value| true },
      :boolean => lambda { |value| true },
      :utf8_smallstring => lambda { |value| value.respond_to?(:to_s) },
      :utf8_text => lambda { |value| value.respond_to?(:to_s) },
      :array => lambda { |value| value.respond_to?(:to_a) },
      :i32 => lambda { |value| value.respond_to?(:to_i) },
      :utc_date_secs => lambda { |value| value.nil? || value.is_a?(Time) || value.respond_to?(:strftime) || value.is_a?(String) },
      :reference => lambda { |value| true }
    }

    RUBY_TO_DB_VALUE = {
      :enum => lambda { |value| value.to_s },
      :boolean => lambda { |value| !!value },
      :utf8_smallstring => lambda { |value| value.to_s } ,
      :utf8_text => lambda { |value| value.to_s },
      :array => lambda { |value| value.to_a },
      :i32 => lambda { |value| value.to_i },
      :utc_date_secs => lambda { |value| value.utc.strftime("%Y%m%dT%H%M%S%z") },
      :reference => lambda { |value| value }
    }

    DB_VALUE_TO_RUBY = {
      :enum => lambda { |value| String(value) },
      :boolean => lambda { |value| (value == 'true' || value == true) },
      :utf8_smallstring => lambda { |value| String(value) },
      :utf8_text => lambda { |value| String(value) },
      :array => lambda { |value| Array(value) },
      :i32 => lambda { |value| Integer(value) },
      :utc_date_secs => lambda { |value| value.nil? ? nil : (value.is_a?(Fixnum) ? Time.at(value) : Time.parse(value)) },
      :reference => lambda { |value| value }
    }

    module ClassMethods
      def schema_attributes
        schema = @static_attributes.nil? ? [] : @static_attributes.map do |attr_name, attrib|
          type = attrib[:type].to_s.upcase
          nullable = (attrib[:opts] && attrib[:opts][:nullable])
          {:name => attr_name, :type => type, :nullable => nullable} unless type == "ENUM"
        end
        unless @enums.nil?
          schema += @enums.map do |enum_name, enum_values|
            nullable = (@static_attributes[enum_name][:opts] && @static_attributes[enum_name][:opts][:nullable])
            {:name => enum_name, :type => "ENUM", :nullable => nullable, :values => enum_values}
          end
        end
        schema.compact
      end

      def schema_indexes
        @indexes.nil? ? [] : @indexes.map do |index_name, index|
          index.serialize
        end
      end

      def schema_counters
        @counters.nil? ? [] : @counters.map do |counter_name, counter|
          counter.serialize
        end
      end

      def schema_fulltexts
        @fulltexts.nil? ? [] : @fulltexts.map do |fulltext_name, fulltext|
          fulltext.serialize
        end
      end

      def to_schema
        {"attributes" => schema_attributes, "indexes" => schema_indexes, "counters" => schema_counters, "fulltexts" => schema_fulltexts}
      end

      def post_schema
        path = "/1.0/s/#{entity_name}"
        data = to_schema.to_json

        ActiveRest::Utility.curl(:post, path, data)
      end

      def put_schema
        response = Connection.http_get_core("/1.0/s/#{entity_name}")

        if response.status == 404
          post_schema
        elsif response.success?
          version = JSON.parse(response.body)["version"]
          path = "/1.0/s/#{entity_name}"
          data = to_schema.merge({:version => version}).to_json

          ActiveRest::Utility.curl(:put, path, data)
        else
          raise response.inspect
        end
      end

      def simple_entity_name
        name.split('::').last.underscore
      end

      def entity_parent
        parents.detect { |p| p.respond_to?(:entity_name) }
      end

      def entity_name
        @entity_name ||=
          begin
            parts = []
            parts << entity_parent.entity_name if entity_parent
            parts << simple_entity_name
            parts.join('-')
          end
      end
    end

    def self.value_from_db(db_type, value)
      return value.nil? ? nil : DB_VALUE_TO_RUBY[db_type].call(value)
    end

    def self.value_to_db(db_type, value)
      value.nil? ? nil : RUBY_TO_DB_VALUE[db_type].call(value)
    end

    def self.class_to_db_type(klass)
      return RUBY_TO_DB_TYPE[klass] if RUBY_TO_DB_TYPE.has_key?(klass)
      :utf8_smallstring
    end

    def self.validate(db_type, value)
      return VALIDATE_DB_TYPE[db_type].call(value)
    end
  end
end
