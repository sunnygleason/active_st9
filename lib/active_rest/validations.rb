module ActiveRest
  module Validations
    extend ActiveSupport::Concern

    class UniquenessValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        index_name = options[:index] || attribute.to_s
        existing = record.class.find_unique(index_name, value)
        record.errors.add(attribute, :taken) if existing && existing != record
      end
    end


    module ClassMethods
      def validates_uniqueness_of(*attr_names)
        validates_with UniquenessValidator, _merge_attributes(attr_names)
      end
    end
  end
end
