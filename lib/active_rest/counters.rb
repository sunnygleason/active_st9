module ActiveRest
  module Counters
    extend ActiveSupport::Concern
    module ClassMethods
      def counter(name, fields, options={})
        @counters ||= {}
        fields_and_types = {}
        fields.each do |f|
          raise Errors::NotStaticAttribute.new(f) unless f == :id || (!@static_attributes.nil? && @static_attributes.keys.include?(f))
          fields_and_types[f] = @static_attributes[f]
        end
        @counters[name] = Counter.new(name, fields_and_types, options)
      end
    end
  end
end
