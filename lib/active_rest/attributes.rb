module ActiveRest
  module Attributes
    BOOLEAN_VALUE_MAP = {
      nil => nil,
      true => true,
      false => false,
      "true" => true,
      "false" => false,
      "0" => false,
      "1" => true,
      0 => false,
      1 => true
    }

    def attributes
      @static_attributes ? Hash[*@static_attributes.map {|attr_name, attrib| [attr_name, self.send("#{attr_name}")]}.flatten] : {}
    end

    def attributes=(attributes)
      update(attributes)
    end

    def define_attribute(attribute_name, attribute_type = :utf8_string, opts = {})
      @static_attributes ||= {}
      @static_attributes[attribute_name] = {:type => attribute_type, :opts => opts}
      @serialized_attributes ||= []
      if opts[:serialized]
        @serialized_attributes << attribute_name
      end

      # all the code is included in the class via an anonymouse module to provide
      # a mechanism for overriding the default implementation via the super chain
      methods = Module.new do
        # raw accessors (no type conversion)
        class_eval <<-END, __FILE__, __LINE__ + 1
          def #{attribute_name}_raw=(val)
            raise Errors::InvalidValue unless Schema.validate(:#{attribute_type}, val)
            #{attribute_name}_will_change! unless val == @#{attribute_name}
            self.instance_variable_set("@#{attribute_name}", val)
          end

          def #{attribute_name}_raw
            @#{attribute_name}
          end
        END

        # type specific accessors (may include type conversion)
        case attribute_type
        when :boolean
          class_eval <<-END, __FILE__, __LINE__ + 1
            def #{attribute_name}=(val)
              self.#{attribute_name}_raw = (BOOLEAN_VALUE_MAP.has_key?(val) && BOOLEAN_VALUE_MAP[val])
            end
            alias_method :#{attribute_name}, :#{attribute_name}_raw

            def #{attribute_name}?
              !!#{attribute_name}_raw
            end
          END
        when :utc_date_secs
          class_eval <<-END, __FILE__, __LINE__ + 1
            def #{attribute_name}=(val)
              unless val.acts_like?(:time)
                val = begin
                  if val.is_a?(String)
                    if val.blank?
                      nil
                    elsif val.match(/^\\d+$/)
                      Time.at(val.to_i)
                    else
                      (Time.zone || Time).parse(val)
                    end
                  elsif val.is_a?(Integer)
                    Time.at(val)
                  else
                    val.to_time
                  end
                rescue
                  val
                end
              end
              val = val.utc rescue nil
              self.#{attribute_name}_raw = val
            end

            def #{attribute_name}
              #{attribute_name}_raw.try(:in_time_zone)
            end
          END
        when :i32
          class_eval <<-END, __FILE__, __LINE__ + 1
            def #{attribute_name}=(val)
              self.#{attribute_name}_raw = !val.nil? ? val.to_i : val
            end
            alias_method :#{attribute_name}, :#{attribute_name}_raw
          END
        else
          class_eval <<-END, __FILE__, __LINE__ + 1
            alias_method :#{attribute_name}=, :#{attribute_name}_raw=
            alias_method :#{attribute_name}, :#{attribute_name}_raw
          END
        end

        # support for serialized attributes
        # TODO check that serialized value fits in attribute_type when writing
        if opts[:serialized]
          class_eval <<-END, __FILE__, __LINE__ + 1
            def #{attribute_name}=(val)
              if val.nil?
                self.#{attribute_name}_raw = nil
              else
                raise Errors::ValidationError, "Only allowed arrays or hashes for serialized attributes." unless (val.is_a?(Hash) || val.is_a?(Array))
                self.#{attribute_name}_raw = val.to_json
              end
            end

            def #{attribute_name}
              #{attribute_name}_raw.is_a?(String) ? JSON.load(#{attribute_name}_raw) : #{attribute_name}_raw
            end
          END
        end
      end
      include methods
    end
  end
end
