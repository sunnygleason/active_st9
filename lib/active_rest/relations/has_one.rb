module ActiveRest
  module Relations
    module HasOne
      extend ActiveSupport::Concern

      module ClassMethods
        # has_one defines an asymmetric one-way relationship similar to belongs_to in ActiveModel
        # Class1 -(has_one)> Class2
        # has_one creates two attributes on the class: attribute and attribute_id
        # attribute_id is automatically set based on the id of attribute; if attribute instance has not yet been saved,
        # instance is saved automatically when parent object is saved and ID is populated at that time.
        # also defines reload_attribute, which allows the relationship to be reloaded if the child object changes.

        # has_one enforces an index on the has_one attribute.

        def has_one(attribute, params={})
          @has_one_relations ||= {}

          unless params.has_key?(:polymorphic)
            klass = (params.has_key?(:kind) ? params[:kind] : attribute).to_s.camelize
            @has_one_relations[attribute.to_s] = klass
          else
            @has_one_relations[attribute.to_s] = nil
          end

          @indexes ||= {}
          @static_attributes ||= {}
          @static_attributes["#{attribute}_id".to_sym] = { :type => :reference, :opts => {:nullable => params[:nullable] } }
          define_attribute_method "#{attribute}_id".to_sym
          define_attribute "#{attribute}_id".to_sym, :reference, {:nullable => params[:nullable]}
          @indexes["#{attribute}_id"] = Index.new("#{attribute}_id", {"#{attribute}_id".to_sym => { :type => :reference }}, :sort => :desc)
          define_has_one_relation attribute, klass
        end

        protected

        def define_has_one_relation(attribute, klass)
          # all the code is included in the class via an anonymouse module to provide
          # a mechanism for overriding the default implementation via the super chain
          methods = Module.new do
            # Non-polymorphic case
            unless klass.nil?
              class_eval <<-STOP, __FILE__, __LINE__ + 1
                def #{attribute}
                  return @#{attribute} unless @#{attribute}.nil?
                  unless self.#{attribute}_id.nil? || self.#{attribute}_id.empty?
                    @#{attribute} ||= #{klass}.find(self.#{attribute}_id.split(":").last)
                  end
                end

                def reload_#{attribute}
                  @#{attribute} =
                    #{klass}.find(self.#{attribute}_id.split(":").last)
                end

                def #{attribute}=(attr)
                  if attr.nil?
                    @#{attribute} = nil
                    self.#{attribute}_id = nil
                    return nil
                  end

                  unless attr.class == #{klass} && attr.class.respond_to?(:find)
                    raise Errors::InvalidAssociation.new(attr.class.to_s, "#{klass}")
                  end

                  @#{attribute} = attr

                  # Populate the ID now, unless we need to defer until save.
                  self.#{attribute}_id = attr.db_id if attr.persisted?
                end
              STOP
            else
              class_eval <<-EOS, __FILE__, __LINE__ + 1
                def #{attribute}
                  return @#{attribute} unless @#{attribute}.nil?
                  unless self.#{attribute}_id.nil? || self.#{attribute}_id.empty?
                    klass, mid = #{attribute}_id.split(':')
                    klass.slice!(0)
                    @#{attribute} ||= klass.gsub('-', '/').camelize.constantize.find(mid)
                  end
                end

                def reload_#{attribute}
                    klass, mid = #{attribute}_id.split(':')
                    klass.slice!(0)
                    @#{attribute} = klass.gsub('-', '/').camelize.constantize.find(mid)
                end

                def #{attribute}=(attr)
                  if attr.nil?
                    @#{attribute} = nil
                    self.#{attribute}_id = nil
                    return nil
                  end

                  unless attr.class.respond_to?(:find)
                    raise Errors::InvalidAssociation.new(attr.class.to_s, 'an object that responds_to :find')
                  end

                  @#{attribute} = attr

                  # Populate the ID now, unless we need to defer until save.
                  self.#{attribute}_id = attr.db_id if attr.persisted?
                end
              EOS
            end
          end
          include methods
        end
      end

      def create_or_save(*args)
        save_relations(*args)
        super
      end

      protected

      def save_relations(*args)
        has_one_relations = self.class.instance_variable_get(:@has_one_relations)
        unless has_one_relations.nil?
          has_one_relations.each do |attribute, klass|
            attr = self.send(attribute)
            unless attr.nil?
              attr.create_or_save(*args) if attr.new_record? || attr.changed_attributes.any?
              self.send("#{attribute}_id=", attr.db_id)
            end
          end
        end
      end
    end
  end
end