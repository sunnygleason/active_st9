require 'pp'

module ActiveRest
  module Query
    extend ActiveSupport::Concern

    VALID_FINDABLE_ID_REGEX = /^([a-z0-9]{16})(\-.*)?$/.freeze

    module ClassMethods
      # Currently we support finding items with a known type and ID or multiple known IDs within a given type.
      # find(String) will find the single entity with given encrypted ID.
      # find(Fixnum) will find the single entity with given sequence.
      # find(Array[String|Fixnum]) will find the entities with given encrypted or
      #   sequence IDs, returned as an array in the queried order. Nil entities will be nil.
      # Sting encrypted IDs can have stuff appended to the end with a hyphen. It'll get stripped automagically.
      def find(id, *args)
        opts = args.last
        opts = {} unless opts.is_a?(Hash)
        opts = opts.reverse_merge({:raise_exception => false, :collapse => true})

        [id].flatten.each { |i| validate_findable_id!(i) }

        res =
          log_with_timing "FIND: #{@base_class.entity_name} : #{id.inspect}" do
            if id.is_a?(Array)
              Connection.multi_get(id.map { |id| to_db_id(id) }, opts.slice(:collapse, :with_quarantined))
            else
              Connection.get(to_db_id(id), opts.slice(:with_quarantined))
            end
          end

        raise Errors::NotFoundError if res.blank? && opts[:raise_exception]

        res
      end

      def find!(id, opts = {})
        find(id, opts.merge(:raise_exception => true))
      end

      # find_with_index takes an index_name, and vals in one of two formats:
      # "val1", "val2", "val3"
      # {"field.operator" => "field_val", "field2.operator" => "field_val"}
      # valid binary operators are +eq+, +ne+ (avoid as this causes an index scan), +gt+, +ge+, +lt+, +le+
      # valid set operators are +in+ where the value is than an Array of ids
      # Optionally a final argument can be passed in as a Hash of options:
      # * +size+:: Fixnum dictating the number of ids/objects to return (See ST9 for default/max)
      # * +token+:: String identifying where to position the cursor. Default to nil or empty
      # Returns an EnumerableResults.
      def find_with_index(index_name, *vals)
        raise Errors::NoIndex.new(index_name) unless index_name == "all" || @indexes.keys.include?(index_name)

        # More than one argument, and the last one is a hash - this means the last one is the options
        if vals.length > 1 && vals.last.is_a?(Hash)
          options = vals.delete(vals.last)
          size = options.delete(:size)
          token = options.delete(:token)
          with_quarantined = options.delete(:with_quarantined)
        end

        log_with_timing "FIND WITH INDEX: #{@base_class.entity_name} : #{index_name} using #{vals}" do
        url = "/1.0/i/#{@base_class.entity_name}"
        url += (index_name == "all") ? ".all?" : "#{@indexes[index_name].find_query(vals)}"
        url += "&n=#{size}" unless size.nil?
        url += "&includeQuarantine=true" if with_quarantined
        response = Connection.http_get_enumerable_results(url, token)
        response.with_quarantined = with_quarantined if response.is_a?(EnumerableResults)
        response
      end
      end

      def exists?(index_name, *vals)
        raise Errors::NoIndex.new(index_name) unless @indexes.keys.include?(index_name)

        log_with_timing "FIND WITH INDEX (EXISTS): #{@base_class.entity_name} : #{index_name} using #{vals}" do
        url = "/1.0/i/#{@base_class.entity_name}#{@indexes[index_name].find_query(vals)}"
        Connection.http_get_exists?(url)
      end
      end

      # find_unique takes an index_name, and vals in one of two formats:
      # "val1", "val2", "val3"
      # {"field.operator" => "field_val", "field2.operator" => "field_val"}
      # valid binary operators are +eq+ only
      # Returns an EnumerableResults.
      def find_unique(index_name, *vals)
        raise Errors::NoIndex.new(index_name) unless @indexes.keys.include?(index_name)
        raise Errors::NonUniqueIndex.new(index_name) unless @indexes[index_name].unique

        # More than one argument, and the last one is a hash - this means the last one is the options
        if vals.length > 1 && vals.last.is_a?(Hash)
          options = vals.delete(vals.last)
          [:size, :token, :with_quarantined].each do |s|
            raise Errors::InvalidArgument.new(s) if options[s]
          end
        end

        log_with_timing "FIND UNIQUE: #{@base_class.entity_name} : #{index_name} using #{vals}" do
          url = "/1.0/u/#{@base_class.entity_name}#{@indexes[index_name].find_query(vals)}"
          res = Connection.http_get(url)

          if res.blank?
            nil
          else
            Serializer.deserialize(res.body)
          end
        end
      end

      def count(counter_name, *vals) # Count: takes counter name and array of values in order that they are defined in the index}
        raise Errors::NoCounter.new(counter_name) unless @counters.keys.include?(counter_name)

        if vals.length > 1 && vals.last.is_a?(Hash) # More than one argument, and the last one is a hash - this means the last one is the options
          options = vals.delete(vals.last)
          size = options.delete(:size)
        end

        log_with_timing "COUNT: #{@base_class.entity_name} : #{counter_name} using #{vals}" do
        url = "/1.0/c/#{@base_class.entity_name}#{@counters[counter_name].count_query(vals)}"
        url += "&n=#{size}" unless size.nil?
        response = Connection.http_get_enumerable_counters(url)
      end
      end

      def all
        find_with_index("all")
      end

      def validate_findable_id!(id)
        valid =
          case id
          when String then !!id.match(VALID_FINDABLE_ID_REGEX) || !!id.match(/^\@#{@base_class.entity_name}\:([a-z0-9]{16})/)
          when Fixnum then true
          else false
          end

        raise Errors::InvalidFindableIDError unless valid
      end

      private

      def to_db_id(id)
        case id
        when String then
          if id.match(VALID_FINDABLE_ID_REGEX)
            "@#{@base_class.entity_name}:#{id.match(VALID_FINDABLE_ID_REGEX)[1]}"
          else
            id
          end
        when Fixnum then "#{@base_class.entity_name}:#{id}"
        else raise Errors::InvalidFindableIDError
        end
      end

      def log_with_timing(msg)
        start = Time.current
        return_value = yield
        finish = Time.current
        duration = ((finish - start).to_f * 1000).to_i
        Config::LOGGER.debug("#{msg} (#{duration}ms)")
        return_value
      end
    end
  end
end
