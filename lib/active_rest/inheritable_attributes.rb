module ActiveRest
  module InheritableAttributes
    def inherited(subclass)
      subclass.instance_variable_set(:@static_attributes, (@static_attributes.dup rescue @static_attributes))
      subclass.instance_variable_set(:@serialized_attributes, (@serialized_attributes.dup rescue @serialized_attributes))
      subclass.instance_variable_set(:@has_one_relations, (@has_one_relations.dup rescue @has_one_relations))
      subclass.instance_variable_set(:@enums, (@enums.dup rescue @enums))
      subclass.instance_variable_set(:@has_many_relations, (@has_many_relations.dup rescue @has_many_relations))
      subclass.instance_variable_set(:@indexes, (@indexes.dup rescue @indexes))
      subclass.instance_variable_set(:@counters, (@counters.dup rescue @counters))
    end
  end
end
