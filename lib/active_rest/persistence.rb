module ActiveRest
  module Persistence
    def save(ignore_errors = false)
      create_or_save(ignore_errors)
    end

    def save!
      create_or_save(false, true)
    end

    def destroy
      response = Connection.destroy(@db_id)
      raise Errors::PersistenceError.new(response.body) unless response.success?
      true
    end

    def persisted?
      !@is_new
    end

    def new_record?
      !!@is_new
    end

    protected

    def create_or_save(ignore_errors = false, raise_errors = false)
      raise Errors::ValidationError.new(self.errors) unless ignore_errors || !raise_errors || self.valid?
      return false unless (self.valid? || ignore_errors)
      @previously_changed = changes
      @changed_attributes.clear
      json_obj = Serializer.serialize(self)
      Config::LOGGER.debug("SAVING: #{json_obj}")
      if @is_new
        response = Connection.create(self.class.instance_variable_get(:@base_class).entity_name, json_obj)
      else
        response = Connection.update(@db_id, json_obj)
      end
      unless response.success?
        case response.status
          when 500 then raise Errors::UnexpectedRemoteServiceError.new("#{response.body} (#{response.status})")
          when 400 then raise Errors::InvalidClientRequestError.new("#{response.body} (#{response.status})")
          when 409 then
            begin
              if (response.body == "version conflict")
                raise Errors::ObsoleteVersionError.new("#{response.body} (#{response.status})")
              elsif (response.body == "unique index constraint violation")
                raise Errors::DuplicateKeyError.new("#{response.body} (#{response.status})")
              end
            end
        end
        raise Errors::PersistenceError.new("#{response.body} (#{response.status})")
      end
      attributes = JSON.parse(response.body)
      @db_id   = attributes["id"]
      @version = attributes["version"]
      @is_new  = false
      true
    end
  end
end
