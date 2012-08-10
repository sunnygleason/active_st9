module ActiveRest
  module Relations
    module HasMany
      # if left to nil, will use ST9 default (100)
      DEFAULT_HAS_MANY_RELATION_GET_SIZE = nil

      extend ActiveSupport::Concern

      module ClassMethods
        def has_many(relation_name, params={})
          @has_many_relations ||= {}
          through_klass = params.delete(:through)
          klass_string = (params.delete(:kind) || relation_name.to_s.classify).to_s
          foreign_key = params.delete(:foreign_key) || "#{self.simple_entity_name}_id"
          cascade_option = params.delete(:dependent) || :delete
          if through_klass
            klass = through_klass.to_s.classify.constantize
            through_target = (params.delete(:target) || klass_string.underscore).to_s
          else
            klass = klass_string.constantize
          end
          @has_many_relations.merge!({relation_name => [klass, foreign_key, through_target, cascade_option]})
          define_has_many_relation relation_name, klass, foreign_key, through_target
        end

        def destroy_with_cascades(ids, opts = {})
          has_many_relations = instance_variable_get(:@has_many_relations)

          if has_many_relations
            raise Errors::CascadeError unless ActiveRest::Config.allow_cascades?

            has_many_relations.each do |name, relation|
              klass, fk, _, cascade_option = relation

              ids.each do |id|
                children = klass.find_with_index(fk, { fk => id }, { :size => DEFAULT_HAS_MANY_RELATION_GET_SIZE, :with_quarantined => true })
                child_ids = []

                unless children.empty?
                  begin child_ids += children.to_ids end until (children = children.next_set).empty?
                  type = child_ids.first.split(':').first.sub(/^\@/, '').gsub('-', '/').camelize.constantize
                  if cascade_option == :destroy
                    klass.find(child_ids).each do |record|
                      record.destroy
                    end
                  else
                    type.destroy_with_cascades(child_ids)
                  end
                end
              end
            end
          end

          ids.each { |id| Connection.destroy(id) } unless opts[:only_children]
        end

        protected

        def define_has_many_relation(relation_name, klass, foreign_key, through_target)
          # all the code is included in the class via an anonymouse module to provide
          # a mechanism for overriding the default implementation via the super chain
          methods = Module.new do
            class_eval <<-STOP, __FILE__, __LINE__ + 1
              # NOTE value is cached by arguments. passing different argument will
              #      invalidate the cache and reload the related records and recache
              def #{relation_name}(limit = DEFAULT_HAS_MANY_RELATION_GET_SIZE, opts = {})
                args = [limit, opts]

                if defined?(@#{relation_name}) && (args == [DEFAULT_HAS_MANY_RELATION_GET_SIZE, {}] || args == @__#{relation_name}_cached_value_arguments)
                  @#{relation_name}
                else
                  reload_#{relation_name}(limit, opts)
                end
              end

              def reload_#{relation_name}(limit = DEFAULT_HAS_MANY_RELATION_GET_SIZE, opts = {})
                @__#{relation_name}_cached_value_arguments = [limit, opts]
                @#{relation_name} = load_#{relation_name}(limit, opts)
              end

              private

              def load_#{relation_name}(limit = DEFAULT_HAS_MANY_RELATION_GET_SIZE, opts = {})
                if db_id.nil? || db_id.empty?
                  []
                else
                  #{klass}.find_with_index(
                    "#{foreign_key}",
                    {"#{foreign_key}.eq" => self.db_id},
                    {:size => limit}.merge(opts)
                  )#{".map(&:" + through_target + ")" if through_target}
                end
              end
            STOP
          end
          include methods
        end
      end

      def destroy(*)
        self.class.destroy_with_cascades([db_id], :only_children => true)
        super
      end

      def self.relations_responding_to(host_class, instance_method)
        has_many_relations = host_class.instance_variable_get(:@has_many_relations)

        if has_many_relations
          has_many_relations.select do |name, (klass, foreign_key, through_target)|
            klass.public_method_defined?(instance_method)
          end
        else
          []
        end
      end
    end
  end
end
