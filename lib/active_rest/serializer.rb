module ActiveRest
  class Serializer
    def self.deserialize(json_string)
      json_hash = JSON.parse(json_string)
      obj_from_hash(json_hash)
    end

    def self.deserialize_multi(multi_json_string, collapse=true, defer_callbacks=false)
      json_hash = JSON.parse(multi_json_string)

      objs =
        json_hash.map do |obj_id, obj|
          next if obj.blank?
          obj_from_hash(obj, defer_callbacks)
        end

      collapse ? objs.compact : objs
    end

    def self.serialize(data_object)
      attributes = data_object.class.instance_variable_get(:@static_attributes) || {}

      version = data_object.version
      acc = version.nil? ? {} : { "version" => version }

      attributes = attributes.inject(acc) do |result, (attr_name, attrib)|
        result[attr_name] = Schema.value_to_db(attrib[:type], data_object.send("#{attr_name}_raw"))
        result
      end
      res = data_object.class.instance_variable_get(:@inherited) ? attributes.merge({"type" => data_object.class.instance_variable_get(:@type)}).to_json : attributes.to_json
    end

    private

    # NOTE: This must only be used for deserializing a record that is already persisted
    def self.obj_from_hash(hash, defer_callbacks = false)
      type = hash.delete("type") # Type for inherited objects, kind otherwise
      kind = hash.delete("kind")
      klass_str = type || kind
      begin
        klass = klass_str.gsub('-', '/').camelize.constantize
      rescue NameError
        raise Errors::InvalidKind.new(klass_str)
      end
      new_obj = klass.allocate
      defined_attributes = klass.instance_variable_get(:@static_attributes)
      hash = hash.inject({}) do |result, (attr_name, attr_value)|
        result[attr_name] = (!defined_attributes.nil? && defined_attributes.has_key?(attr_name.to_sym)) ? Schema.value_from_db(defined_attributes[attr_name.to_sym][:type], attr_value) : attr_value
        result
      end
      new_obj.send("update_raw", hash)
      new_obj.instance_variable_set(:@changed_attributes, {})
      new_obj.send("_run_find_callbacks") unless defer_callbacks
      new_obj.send("_run_initialize_callbacks") unless defer_callbacks
      new_obj
    end
  end
end

