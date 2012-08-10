module ActiveRest
  module Quarantinable
    class << self
      def quarantine!(db_id)
        response = Connection.http_post(quarantine_path(db_id), nil)
        response.success? or raise Errors::QuarantineError.new(response)
      end

      def unquarantine!(db_id)
        response = Connection.http_delete(quarantine_path(db_id))
        response.success? or raise Errors::QuarantineError.new(response)
      end

      def quarantine_path(db_id)
        "/1.0/q/#{db_id}"
      end

      def quarantine_children!(host)
        relations = Relations::HasMany.relations_responding_to(host.class, :quarantine!)

        if !relations.empty?
          raise Errors::CascadeError unless ActiveRest::Config.allow_cascades?

          relations.each do |name, relation|
            records, ids = host.send(name), []
            unless records.empty?
              begin ids += records.to_ids end until (records = records.next_set).empty?
              ids.each { |id| quarantine!(id) }
            end
          end
        end
      end

      def unquarantine_children!(host)
        relations = Relations::HasMany.relations_responding_to(host.class, :unquarantine!)

        if !relations.empty?
          raise Errors::CascadeError unless ActiveRest::Config.allow_cascades?

          relations.each do |name, relation|
            records, ids = host.send(name, Relations::HasMany::DEFAULT_HAS_MANY_RELATION_GET_SIZE, :with_quarantined => true), []
            unless records.empty?
              begin ids += records.to_ids end until (records = records.next_set).empty?
              ids.each { |id| unquarantine!(id) }
            end
          end
        end
      end
    end

    def quarantine!
      Quarantinable.quarantine_children!(self)
      Quarantinable.quarantine!(db_id)
    end

    def unquarantine!
      Quarantinable.unquarantine_children!(self)
      Quarantinable.unquarantine!(db_id)
    end

    def quarantined?
      path = Quarantinable.quarantine_path(db_id)
      response = Connection.http_get_core(path)

      if response.success?
        !!JSON.parse(response.body)['$quarantined']
      else
        case response.status
        when 404 then raise Errors::NotFoundError
        else raise Errors::QuarantineError.new(response)
        end
      end
    end
  end
end
