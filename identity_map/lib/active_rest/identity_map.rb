require "active_rest"
require "active_rest/identity_map/clear_middleware"
require "active_rest/identity_map/railtie" if defined?(Rails)
require "active_rest/identity_map/connection/identity_mappable"

module ActiveRest
  module IdentityMap
    class << self
      def set(key, obj)
        thread_local_hash[key] = obj
      end

      def get(key)
        thread_local_hash[key]
      end

      def fetch(key)
        get(key) || set(key, yield)
      end

      def remove(key)
        thread_local_hash.delete(key)
      end

      def clear
        Thread.current[:active_rest_identity_map_current_thread_hash] = nil
      end

      private

      def thread_local_hash
        Thread.current[:active_rest_identity_map_current_thread_hash] ||= Hash.new
      end
    end
  end
end
