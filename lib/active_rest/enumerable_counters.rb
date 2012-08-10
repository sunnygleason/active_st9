module ActiveRest
  class EnumerableCounters
    include Enumerable
    def initialize(counts, base_url = nil, prev_url = nil, next_url = nil)
      @counts = counts
      @base = base_url
      @prev = prev_url
      @next = next_url
    end

    attr_reader :counts

    def [](index)
      @all_elements[index]
    end

    def each
      @all_elements.each {|obj| yield obj }
    end

    def next_set
      return [] if @next.nil?
      Connection.http_get_enumerable_counters(@base, @next)
    end

    def prev_set
      return [] if @prev.nil?
      Connection.http_get_enumerable_counters(@base, @prev)
    end

    def size
      @counts.size
    end

    def length
      @counts.length
    end

    def as_json(options)
      self.map { |res| res.as_json(options) }
    end
  end
end
