require "cgi"

module ActiveRest
  class Index
    attr_reader :name, :properties, :unique

    @name = []
    @unique = false
    @fields = {}
    @properties = []

    def initialize(name, fields, properties = {})
      @name = name
      @fields = fields # {fieldname => type, ...}
      @properties = properties # :sort for now
      raise ActiveRest::Errors::InvalidIndex unless @properties.keys.include?(:sort)
      @sort = @properties.delete(:sort).to_s.upcase
      @unique = @properties.delete(:unique)
      @fields.merge!(:id => { :type => :reference, :opts => {} }) unless @unique
    end

    def fields
      @fields.keys
    end

    def serialize
      cols = fields.map{|field| {"name" => field}.merge({:sort => @sort}).merge(properties) }

      {
        "name" => @name,
        "unique" => @unique,
        "cols" => cols
      }
    end

    def find_query(conditions)
      if conditions.first.is_a?(Hash)
        conditions = conditions.first
      else
        conditions = Hash[*@fields.except(:id).keys.zip(conditions).flatten]
      end

      fields_query = conditions.map do |fieldspec, value|
        field_name, operator = fieldspec.to_s.split(".")
        operator ||= " eq "
        db_value =
          case value
          when Array
            mvs = value.map { |v| quote(Schema.value_to_db(@fields[field_name.to_sym][:type], v)) }
            "(#{mvs.join(',')})"
          else
            quote(Schema.value_to_db(@fields[field_name.to_sym][:type], value))
          end
        "#{field_name} #{operator} #{db_value}"
      end.compact.join(" and ")
      ".#{@name}?q=#{CGI::escape(fields_query)}"
    end

  private
    def quote(value)
      case value
      when String, Symbol then "\"#{quote_string(value.to_s)}\""
      when Numeric then value.to_s
      when true, false then value ? 'true' : 'false'
      when NilClass then 'null'
      else raise "Unknown type passed into quote: #{value.class.to_s}"
      end
    end

    def quote_string(s)
      s.gsub(/\\/, '\\\\\\\\').gsub(/"/, '\"')
    end
  end
end
