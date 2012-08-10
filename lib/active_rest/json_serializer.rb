module ActiveRest
  module JsonSerializer
    def as_json(options = {})
      options ||= {}
      attributes = self.class.instance_variable_get(:@static_attributes) || {}
      only = options[:only]
      attributes = attributes.inject({}) do |result, (attr_name, attr_type)|
        result[attr_name] = send(attr_name) if only.nil? || only.include?(attr_name.to_sym) 
        result
      end
      include = options[:include] || {}
      include.keys.each do |include_field|
        attributes[include_field] = send(include_field).as_json(include[include_field]) # Send params onwards to children, infinite nest is possible
      end
      attributes[:id] = self.id
      attributes
    end
  end
end

