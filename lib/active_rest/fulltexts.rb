module ActiveRest
  module Fulltexts
    extend ActiveSupport::Concern
    module ClassMethods
      def fulltext(fields, options={})
        @fulltexts ||= {}
        fields_and_types = {}
        fields.each do |f|
          raise Errors::NotStaticAttribute.new(f) unless f == :id || (@static_attributes && @static_attributes.keys.include?(f))
          fields_and_types[f] = @static_attributes[f]
        end

        fulltext_def = Fulltext.new(fields_and_types, options)
        raise ActiveRest::Errors::InvalidIndex if (@fulltexts[:fulltext] && @fulltexts[:fulltext].fields != fulltext_def.fields)
        @fulltexts.merge!({:fulltext => fulltext_def})
      end
    end
  end
end
