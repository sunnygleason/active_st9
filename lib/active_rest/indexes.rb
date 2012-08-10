module ActiveRest
  module Indexes
    extend ActiveSupport::Concern
    module ClassMethods
      def index(name, fields, options={})
        @indexes ||= {}
        fields_and_types = {}
        fields.each do |f|
          raise Errors::NotStaticAttribute.new(f) unless f == :id || (!@static_attributes.nil? && @static_attributes.keys.include?(f))
          fields_and_types[f] = @static_attributes[f]
        end
        @indexes.merge!({name => Index.new(name, fields_and_types, options)})
      end
    end
  end
end
