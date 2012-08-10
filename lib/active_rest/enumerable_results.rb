module ActiveRest
  class EnumerableResults
    include Enumerable
    delegate :reject, :reject!, :include?, :to => :to_a
    attr_reader :next, :prev, :defer_callbacks
    attr_writer :with_quarantined, :defer_callbacks

    def initialize(ids_or_records, base_url = nil, prev_token = nil, next_token = nil)
      if ids_or_records.compact[0].is_a?(String)
        @ids = ids_or_records
      else
        @all_elements = ids_or_records
        @ids = @all_elements.map {|r| r.db_id unless r.nil?}
      end
      @base = base_url
      @prev = prev_token
      @next = next_token
      @with_quarantined = false
      @defer_callbacks = false
    end

    def with_quarantined?
      !!@with_quarantined
    end

    def defer_callbacks?
      !!@defer_callbacks
    end

    def [](index)
      if @all_elements
        @all_elements[index]
      else
        method =
          case index
          when Integer then :get
          when Range then :multi_get
          end
        @ids[index].nil? ? nil : Connection.send(method, @ids[index], :with_quarantined => with_quarantined?)
      end
    end

    def first(number=nil) # why this isn't how Enumerable is implemented, I don't know...
      if number.nil?
        self[0]
      else
        return EnumerableResults.new([]) if number <= 0
        EnumerableResults.new(self[0..(number-1)]).tap do |results|
          results.with_quarantined = with_quarantined?
        end
      end
    end

    def each
      @all_elements ||= Connection.multi_get(@ids.compact, :with_quarantined => with_quarantined?, :defer_callbacks => defer_callbacks?)
      @all_elements.each {|obj| yield obj }
    end

    def next_set
      return EnumerableResults.new([]) if @next.nil?
      Connection.http_get_enumerable_results(@base, @next).tap do |r|
        r.with_quarantined = with_quarantined? if r.is_a?(EnumerableResults)
      end
    end

    def prev_set
      return EnumerableResults.new([]) if @prev.nil?
      Connection.http_get_enumerable_results(@base, @prev).tap do |r|
        r.with_quarantined = with_quarantined? if r.is_a?(EnumerableResults)
      end
    end

    def map_children(*attributes)
      entity_ids = self.inject([]) do |accum, entity|
        attributes.each do |attribute|
          prop = "#{attribute}_id"
          accum << entity.send(prop) unless entity.nil? || !entity.respond_to?(prop)
        end
        accum
      end
      ActiveRest::EnumerableResults.new(entity_ids).tap do |r|
        r.defer_callbacks = self.defer_callbacks
        r.with_quarantined = with_quarantined?
      end
    end

    def includes(*attributes)
      full_todo = attributes.size == 1 ? attributes.first : attributes

      todo =
        if full_todo.is_a?(Symbol)
          [full_todo]
        elsif full_todo.is_a?(Array)
          full_todo.uniq
        elsif full_todo.is_a?(Hash)
          full_todo.keys
        else
          raise InvalidArgument(attributes)
        end

      found = map_children(*todo).to_map

      update_attributes(@all_elements, todo, found)

      if full_todo.is_a?(Hash)
        ActiveRest::EnumerableResults.new(found.values).tap do |r|
          r.defer_callbacks = self.defer_callbacks
          r.with_quarantined = with_quarantined?
        end.includes(*(full_todo.values.flatten))
      end

      self
    end

    def size
      @ids.size
    end

    def length
      @ids.length
    end

    # TODO: I wonder if we should check to see if there is a previous token.  Depends
    # on what semantics we want EnumerableResult to take on I suppose
    def empty?
      size == 0
    end

    def to_ids
      @ids
    end

    def to_map
      self.inject({}) do |accum, entity|
        accum[entity.db_id] = entity if entity
        accum
      end
    end

    def |(union_ids)
      EnumerableResults.new(@ids | union_ids.to_ids).tap do |r|
        r.with_quarantined = with_quarantined? || union_ids.with_quarantined?
      end
    end

    def &(intersection_ids)
      EnumerableResults.new(@ids & intersection_ids.to_ids) do |r|
        r.with_quarantined = with_quarantined? || intersection_ids.with_quarantined?
      end
    end

    def -(difference_ids)
      EnumerableResults.new(@ids - difference_ids.to_ids).tap do |r|
        r.with_quarantined = with_quarantined? || difference_ids.with_quarantined?
      end
    end

    def +(append_ids)
      EnumerableResults.new(@ids + append_ids.to_ids) do |r|
        r.with_quarantined = with_quarantined? || append_ids.with_quarantined?
      end
    end

    def uniq
      EnumerableResults.new(@ids.uniq).tap do |r|
        r.with_quarantined = with_quarantined?
      end
    end

    def as_json(options)
      self.map { |res| res.as_json(options) }
    end

    # FIXME: This is a horrible, horrible hack to tide us over until we have
    # counters or some other method to track the total size of a collection via
    # ActiveREST. I fully expect this method to differ according to type of
    # collection
    def total_size
      size
    end

    def hash
      @ids.hash
    end

    def eql?(v)
      if v.respond_to?(:to_ids)
        to_ids == v.to_ids
      elsif v.respond_to?(:all?) && v.all? { |vv| vv.respond_to?(:db_id) }
        to_ids == v.map(&:db_id)
      else
        false
      end
    end

    def ==(v)
      eql?(v)
    end

    private

    # update the specified (single symbol or array of) attribute(s) in the
    # specified originals from the given "found" value map
    def update_attributes(originals, attributes, found)
      attributes = [attributes] if attributes.is_a?(Symbol)
      originals.each_with_index do |element, idx|
        attributes.each do |attribute|
          prop = "#{attribute}_id"
          if element && element.respond_to?(prop)
            record = found[element.send(prop)]
            element.send(:instance_variable_set, "@#{attribute}", record) if record
          end
        end
      end
    end
  end
end
