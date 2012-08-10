module ActiveRest
  class Fulltext
    attr_reader :name, :properties

    def initialize(fields, properties = {})
      # note: in the future, we will support multiple fulltext indexes per schema
      @name = "fulltext"

      # note: this *may* be better modeled by a belongs_to relation in the future;
      # we avoid that restriction for now while we test this design
      props_clone = properties.clone
      @parent_type = props_clone.delete(:parent_type)
      @parent_identifier_attribute = props_clone.delete(:parent_identifier_attribute)

      @fields = fields
      raise Errors::InvalidIndex unless @fields.size > 0

      @properties = props_clone
    end

    def fields
      @fields.keys
    end

    def serialize
      cols = fields.map{|field| {"name" => field}.merge(properties) }

      {
        "name" => @name,
        "parentType" => @parent_type,
        "parentIdentifierAttribute" => @parent_identifier_attribute,
        "cols" => cols
      }
    end
  end
end
