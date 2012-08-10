module ActiveRest
  module Connection
    mattr_accessor :http_client
    DEFAULT_HTTP_HEADERS = {"Content-Type" => "application/json",'Connection' => 'close'}
    MULTIGET_BATCH_MAX   = 100

    #
    # Entity CRUD
    #

    def self.create(etype, json)
      Connection.http_post("/1.0/e/#{etype}", json)
    end

    def self.get(eid, opts = {})
      uri = "/1.0/e/#{eid}"
      uri << "?includeQuarantine=true" if opts[:with_quarantined]
      response = self.http_get(uri)
      return response.nil? ? nil : Serializer.deserialize(response.body)
    end

    def self.update(eid, json)
      Connection.http_put("/1.0/e/#{eid}", json)
    end

    def self.destroy(eid)
      self.http_delete("/1.0/e/#{eid}")
    end

    def self.multi_get(ids, opts = {})
      return [] if ids.empty?
      opts[:collapse] = true unless opts.has_key?(:collapse)

      result = []
      ids.uniq.each_slice(MULTIGET_BATCH_MAX) do |slice|
        uri = "/1.0/e/multi?"
        slice.each do |id|
          uri << "k=#{id}&" # Trailing & on URL is OK.
        end
        uri << "includeQuarantine=true" if opts[:with_quarantined]
        response = self.http_get(uri)
        result += Serializer.deserialize_multi(response.body, !!opts[:collapse], !!opts[:defer_callbacks]) if response
      end
      result
    end

    #
    # Enumerables
    #

    def self.http_get_enumerable_results(uri, token=nil)
      base_uri = uri
      uri = "#{uri}&s=#{token}" unless token.nil?
      response = self.http_get(uri)
      results = JSON.parse(response.body)
      return response.nil? ? [] : EnumerableResults.new(results["results"].map { |r| r["id"] }, base_uri, results["prev"], results["next"])
    end

    def self.http_get_exists?(uri)
      if response = self.http_get("#{uri}&n=1")
        JSON.parse(response.body)["results"].size > 0
      else
        false
      end
    end

    def self.http_get_enumerable_counters(uri, token=nil)
      base_uri = uri
      uri = "#{uri}&s=#{token}" unless token.nil?
      response = self.http_get(uri)

      return [] if response.nil?

      results = JSON.parse(response.body)
      q = results["query"]
      r = results["results"].map{|x| q.merge(x) }

      EnumerableCounters.new(r, base_uri, results["prev"], results["next"])
    end

    def self.http_get(uri) # TODO: should probably be factored into a Connection module
      response = self.http_get_core(uri)
      return nil if response.status == 404
      raise Errors::PersistenceError.new(response.body) unless response.success?
      response
    end

    def self.http_get_core(uri)
      request(:GET, uri, nil, DEFAULT_HTTP_HEADERS)
    end

    def self.http_post(uri, json_data)
      request(:POST, uri, json_data, DEFAULT_HTTP_HEADERS)
    end

    def self.http_put(uri, json_data)
      request(:PUT, uri, json_data, DEFAULT_HTTP_HEADERS)
    end

    def self.http_delete(uri)
      request(:DELETE, uri, nil, DEFAULT_HTTP_HEADERS)
    end

    def self.request(method, uri, body, headers)
      headers = prepare_headers(headers)

      @@http_client.request(method, uri, body, headers)
    end

    if defined?(ActiveRest::REQUEST_INFO)
      def self.prepare_headers(headers)
        extended_headers = ActiveRest::REQUEST_INFO.get

        if extended_headers
          headers.merge(extended_headers)
        else
          headers
        end
      end
    else
      def self.prepare_headers(headers)
        headers
      end
    end

    def self.ping
      self.http_get("/ping")
    end
  end
end

module SillyPutty
  class Response
    def success?
      @status >= 200 && @status <= 300
    end
  end
end
