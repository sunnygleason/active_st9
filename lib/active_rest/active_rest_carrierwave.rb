# encoding: utf-8

require 'active_rest'
require 'carrierwave/validations/active_model'

module CarrierWave
  module ActiveRest
    include CarrierWave::Mount
    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader, options={}, &block)
      options[:mount_on] ||= "#{column}_filename"
      utf8_smallstring options[:mount_on]

      super

      alias_method :read_uploader, :read_uploader_activerest
      alias_method :write_uploader, :write_uploader_activerest

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of  column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)

      after_save "store_#{column}!".to_sym
      before_save "write_#{column}_identifier".to_sym
      after_destroy "remove_#{column}!".to_sym
    end

    module InstanceMethods
      def read_uploader_activerest(col)
        self.send(col)
      end
      def write_uploader_activerest(col, val)
        self.send("#{col}=", val)
      end
    end # InstanceMethods
  end # ActiveRest
end # CarrierWave

ActiveRest::Base.extend CarrierWave::ActiveRest
ActiveRest::Base.send(:include, CarrierWave::ActiveRest::InstanceMethods)
