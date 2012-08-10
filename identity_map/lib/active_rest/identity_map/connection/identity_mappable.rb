require "active_support/core_ext"

module ActiveRest
  module IdentityMap
    module Connection
      module IdentityMappable
        extend ActiveSupport::Concern

        module ClassMethods
          def get_with_identity_map(eid, opts = {})
            IdentityMap.fetch(eid) do
              self.get_without_identity_map(eid, opts)
            end
          end

          def update_with_identity_map(eid, json)
            IdentityMap.remove(eid)
            self.update_without_identity_map(eid, json)
          end

          def destroy_with_identity_map(eid)
            IdentityMap.remove(eid)
            self.destroy_without_identity_map(eid)
          end

          # Unclear if we care about ordering here.  However, I preserve order as much
          # as possible considering we drop nil items
          def multi_get_with_identity_map(eids, opts = {})
            opts[:collapse] = true unless opts.has_key?(:collapse)
            fhash = {}

            # First, check the identity_map for anything that we may have local
            eids.each do |eid|
              v = IdentityMap.get(eid)
              fhash[eid] = v if v.present?
            end

            mg_eids = eids - fhash.keys

            # We could early exit if mg_eids.size == 0 but easier not to dup order logic
            the_rest = (mg_eids.size == 0) ? [] : self.multi_get_without_identity_map(mg_eids, opts)

            the_rest.each do |tre|
              fhash[tre.db_id] = IdentityMap.set(tre.db_id, tre)
            end

            objs = eids.map { |eid| fhash[eid] }
            !!opts[:collapse] ? objs.compact : objs
          end
        end

        included do
          class << self
            alias_method_chain :get, :identity_map
            alias_method_chain :update, :identity_map
            alias_method_chain :destroy, :identity_map
            alias_method_chain :multi_get, :identity_map
          end
        end
      end
    end
  end
end

unless ENV['DISABLE_IDENTITY_MAP']
  $stderr.puts('Enabling identity map')
  ActiveRest::Connection.send(:include, ActiveRest::IdentityMap::Connection::IdentityMappable)
end
