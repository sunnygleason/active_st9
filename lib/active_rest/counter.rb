require "cgi"

module ActiveRest
  class Counter
    attr_reader :name, :properties

    def initialize(name, fields, properties = {})
      @name = name
      @fields = fields # {fieldname => type, ...}
      @properties = properties # :sort for now
      raise ActiveRest::Errors::InvalidCounter unless @properties.keys.include?(:sort)
      @sort = @properties.delete(:sort).to_s.upcase
    end

    def serialize
      {"name" => @name, "cols" => @fields.keys.map { |field| {"name" => field}.merge({:sort => @sort}).merge(properties) }}
    end

    def count_query(vals)
      query = ".#{@name}"
      if (vals.size > 0)
        query += "/" + vals.map{|x| CGI::escape(x.to_s) }.join("/")
      end
      query
    end

    def fields
      @fields.keys
    end
  end
end
