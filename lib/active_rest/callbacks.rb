module ActiveRest
  module Callbacks
    def self.included(base)
      base.class_eval do
        extend ActiveModel::Callbacks
        include ActiveModel::Validations::Callbacks

        define_model_callbacks :initialize, :find, :only => :after
        define_model_callbacks :save, :create, :update, :destroy
      end
    end

    # NOTE: This initializer is for new records only. Saved records are initalized via ActiveRest::Serializer#obj_from_hash
    def initialize(*)
      super
      _run_initialize_callbacks
    end

    def destroy(*)
      _run_destroy_callbacks { super }
    end

    def create_or_save(*)
      if @is_new
        _run_create_callbacks {_run_save_callbacks { super } }
      else
        _run_save_callbacks { super }
      end
    end

    #def create(*)
    #  _run_create_callbacks { super }
    #end

    def update(*)
      _run_update_callbacks { super }
    end
  end
end
