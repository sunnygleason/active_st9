module ActiveRest
  module StaticAttributes
    extend ActiveSupport::Concern

    module ClassMethods
      # TODO only permit utf8_text/utf8_smallstring for serialzed_attributes, raise exception for other types
      (Schema::RUBY_TO_DB_TYPE.values + [:reference]).each do |db_type|
        eval <<-END
          def #{db_type.to_s}(attribute_name, opts = {})
            define_attribute_method attribute_name
            define_attribute attribute_name, :#{db_type}, opts
          end
        END
      end
    end
  end
end
