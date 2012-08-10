module ActiveRest
  module Timestamps
    def self.included(base)
      base.class_eval do
        utc_date_secs :created_at
        utc_date_secs :updated_at
      end
    end

    def create_or_save(*)
      self.created_at = Time.now.utc.change(:usec => 0) if @is_new
      self.updated_at = Time.now.utc.change(:usec => 0)
      super
    end
  end
end
