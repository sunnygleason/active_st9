module ActiveRest
  module Enum
    extend ActiveSupport::Concern

    module ClassMethods
      def enum(attribute_name, values, opts = {})
        @enums ||= {}
        @enums[attribute_name.to_sym] = values
        @static_attributes ||= {}
        @static_attributes[attribute_name] = {:type => :enum, :opts => opts }
        define_attribute_method attribute_name
        define_attribute attribute_name, :enum, opts
      end
    end
  end
end
