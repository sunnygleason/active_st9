module Sunspot #:nodoc:
  module Rails #:nodoc:
    module Searchable
      module ClassMethods
        def solr_index(opts={}) ## MONKEYPATCH! This removes find_in_batches/batched indexing support since we don't find in batches yet in ActiveREST (we are too hardcore).
          Sunspot.index!(all)
        end
      end
    end

    module Adapters
      class ActiveRestInstanceAdapter < Sunspot::Adapters::InstanceAdapter
        def id
          @instance.id
        end
      end

      class ActiveRestDataAccessor < Sunspot::Adapters::DataAccessor
        def load(id)
          @clazz.find(id)
        end

        def load_all(ids)
          @clazz.find(ids)
        end
      end
    end
  end
end
