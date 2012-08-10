require 'test_helper'

class IndexTest < MiniTest::Unit::TestCase
  def test_multi_index
    m = MultiIndexHost.new
    m.test_int_one = 1
    m.test_int_two = 3
    m.save
    assert_equal MultiIndexHost.find_with_index("test_ints", 1, 3).size, 1
    assert_equal MultiIndexHost.find_with_index("test_ints", 3, 1).size, 0
  end

  def test_unique_string_index
    assert_equal UniqueStringIndexHost.find_with_index("uniq", "testing123").size, 0

    u1 = UniqueStringIndexHost.new
    u1.test_uniq_string = "testing123"
    u1.save

    assert_equal UniqueStringIndexHost.find_with_index("uniq", "testing123").size, 1
    assert_equal UniqueStringIndexHost.find_unique("uniq", ["testing123"]).db_id, u1.db_id
    assert_equal UniqueStringIndexHost.find_unique("uniq", ["testing124"]), nil

    u2 = UniqueStringIndexHost.new
    u2.test_uniq_string = "testing234"
    u2.save

    assert_equal UniqueStringIndexHost.find_with_index("uniq", "testing234").size, 1

    u2.test_uniq_string = "testing123"
    assert_raises ActiveRest::Errors::DuplicateKeyError, "Save with duplicate key did not raise exception" do
      u2.save
    end
  end

  def test_unique_string_transform_index
    assert_equal UniqueStringTransformIndexHost.find_with_index("uniq", "testing123").size, 0

    u1 = UniqueStringTransformIndexHost.new
    u1.test_uniq_string = "testing123"
    u1.save

    assert_equal UniqueStringTransformIndexHost.find_with_index("uniq", "testing123").size, 1
    assert_equal UniqueStringTransformIndexHost.find_unique("uniq", ["testing123"]).db_id, u1.db_id
    assert_equal UniqueStringTransformIndexHost.find_unique("uniq", ["TESTING123"]).db_id, u1.db_id
    assert_equal UniqueStringTransformIndexHost.find_unique("uniq", ["testing124"]), nil

    u2 = UniqueStringTransformIndexHost.new
    u2.test_uniq_string = "testing234"
    u2.save

    assert_equal UniqueStringTransformIndexHost.find_with_index("uniq", "testing234").size, 1

    u2.test_uniq_string = "TESTING123"
    assert_raises ActiveRest::Errors::DuplicateKeyError, "Save with duplicate key did not raise exception" do
      u2.save
    end
  end

  def test_unique_int_index
    assert_equal UniqueIntIndexHost.find_with_index("uniq", 999).size, 0

    u1 = UniqueIntIndexHost.new
    u1.test_uniq_int = 999
    u1.save

    assert_equal UniqueIntIndexHost.find_with_index("uniq", 999).size, 1
    assert_equal UniqueIntIndexHost.find_unique("uniq", [999]).db_id, u1.db_id
    assert_equal UniqueIntIndexHost.find_unique("uniq", ["999"]).db_id, u1.db_id
    assert_equal UniqueIntIndexHost.find_unique("uniq", [998]), nil

    u2 = UniqueIntIndexHost.new
    u2.test_uniq_int = 990
    u2.save

    assert_equal UniqueIntIndexHost.find_with_index("uniq", 990).size, 1
    assert_equal UniqueIntIndexHost.find_unique("uniq", [999]).db_id, u1.db_id
    assert_equal UniqueIntIndexHost.find_unique("uniq", [990]).db_id, u2.db_id
    assert_equal UniqueIntIndexHost.find_unique("uniq", [998]), nil

    u2.test_uniq_int = 999
    assert_raises ActiveRest::Errors::DuplicateKeyError, "Save with duplicate key did not raise exception" do
      u2.save
    end

    assert_equal UniqueIntIndexHost.find_unique("uniq", [999]).db_id, u1.db_id
    assert_equal UniqueIntIndexHost.find_unique("uniq", [990]).db_id, u2.db_id
  end

  def test_unique_composite_index
    assert_equal UniqueCompositeIndexHost.find_with_index("uniq", "testing123", 999).size, 0

    u0 = UniqueCompositeIndexHost.new
    u0.test_uniq_string = "testing234"
    u0.test_uniq_int = 999
    u0.save

    assert_equal UniqueCompositeIndexHost.find_with_index("uniq", "testing234", 999).size, 1
    assert_equal UniqueCompositeIndexHost.find_unique("uniq", "testing234", 999).db_id, u0.db_id
    assert_equal UniqueCompositeIndexHost.find_unique("uniq", "testing234", 998), nil

    u1 = UniqueCompositeIndexHost.new
    u1.test_uniq_string = "testing123"
    u1.test_uniq_int = 999
    u1.save

    assert_equal UniqueCompositeIndexHost.find_with_index("uniq", "testing123", 999).size, 1
    assert_equal UniqueCompositeIndexHost.find_unique("uniq", "testing123", 999).db_id, u1.db_id
    assert_equal UniqueCompositeIndexHost.find_unique("uniq", "testing234", 999).db_id, u0.db_id
    assert_equal UniqueCompositeIndexHost.find_unique("uniq", "testing", 999), nil

    u2 = UniqueCompositeIndexHost.new
    u2.test_uniq_string = "testing123"
    u2.test_uniq_int = 998
    u2.save

    assert_equal UniqueCompositeIndexHost.find_with_index("uniq", "testing123", 998).size, 1

    u3 = UniqueCompositeIndexHost.new
    u3.test_uniq_string = "testing123"
    u3.test_uniq_int = 990
    u3.save

    assert_equal UniqueCompositeIndexHost.find_with_index("uniq", "testing123", 990).size, 1

    u2.test_uniq_int = 999
    assert_raises ActiveRest::Errors::DuplicateKeyError, "Save with duplicate key did not raise exception" do
      u2.save
    end

    u3.test_uniq_int = 998
    assert_raises ActiveRest::Errors::DuplicateKeyError, "Save with duplicate key did not raise exception" do
      u3.save
    end

    u1.test_uniq_string = "testing234"
    assert_raises ActiveRest::Errors::DuplicateKeyError, "Save with duplicate key did not raise exception" do
      u1.save
    end

    assert_equal UniqueCompositeIndexHost.find_with_index("uniq", "testing123", 999).size, 1
    assert_equal UniqueCompositeIndexHost.find_with_index("uniq", "testing234", 999).size, 1
  end

  def test_index_operator_in_simple
    a = SimpleInHost.create(:int => 50)
    b = SimpleInHost.create(:int => 50)
    c = SimpleInHost.create(:int => 55)
    d = SimpleInHost.create(:int => 55)

    results = SimpleInHost.find_with_index('idx', { 'int.in' => [100] })
    assert_equal 0, results.size

    results = SimpleInHost.find_with_index('idx', { 'int.in' => [55] })
    assert_equal 2, results.size
    assert_equal [c, d].map(&:id).sort, results.map(&:id).sort

    results = SimpleInHost.find_with_index('idx', { 'int.in' => [55, 50] })
    assert_equal 4, results.size
    assert_equal [a, b, c, d].map(&:id).sort, results.map(&:id).sort
  end

  def test_index_operator_in_compound
    a = MultiInHost.create(:int => 100, :sm_string => 'doh')
    b = MultiInHost.create(:int => 200, :sm_string => 'doh')
    c = MultiInHost.create(:int => 300, :sm_string => 'doh')
    d = MultiInHost.create(:int => 200, :sm_string => 'mi')
    e = MultiInHost.create(:int => 100, :sm_string => 'mi')

    results = MultiInHost.find_with_index('idx', { 'int.in' => [100, 200], 'sm_string.eq' => 'mi' })
    assert_equal 2, results.size
    assert_equal [d, e].map(&:id).sort, results[0..1].map(&:id).sort

    results = MultiInHost.find_with_index('idx', { 'sm_string.in' => ['doh', 'mi'], 'int.eq' => 100 })
    assert_equal 2, results.size
    assert_equal [a, e].map(&:id).sort, results[0..1].map(&:id).sort

    results = MultiInHost.find_with_index('idx', { 'sm_string.in' => ['mi'], 'int.gt' => 100 })
    assert_equal 1, results.size
    assert_equal d.id, results.first.id
  end

  def test_index_operator_in_enum
    one = EnumInHost.create(:number => "one")
    two = EnumInHost.create(:number => "two")
    two2 = EnumInHost.create(:number => "two")
    fou = EnumInHost.create(:number => "four")
    fiv = EnumInHost.create(:number => "five")
    fiv2 = EnumInHost.create(:number => "five")

    # with 1 match
    results = EnumInHost.find_with_index('idx', { 'number.in' => %w[one] })
    assert_equal [one], results.to_a

    # with 2 matches
    results = EnumInHost.find_with_index('idx', { 'number.in' => %w[five] })
    assert_equal [fiv2, fiv], results.to_a

    # with 2 matches, diff. enums
    results = EnumInHost.find_with_index('idx', { 'number.in' => %w[five one] })
    assert_equal [fiv2, fiv, one], results.to_a

    # with no matches, valid enum
    results = EnumInHost.find_with_index('idx', { 'number.in' => %w[three] })
    assert_equal [], results.to_a

    # with no value
    assert_raises ActiveRest::Errors::PersistenceError do
      EnumInHost.find_with_index('idx', { 'number.in' => %w[] })
    end

    # with invalid enum
    assert_raises ActiveRest::Errors::PersistenceError do
      EnumInHost.find_with_index('idx', { 'number.in' => %w[six] })
    end

    # with 1 valid, 1 invalid enum
    assert_raises ActiveRest::Errors::PersistenceError do
      EnumInHost.find_with_index('idx', { 'number.in' => %w[one six] })
    end
  end

  def test_index_with_quoted_value
    qs = StringHost.create(:str => '"To be or not to be"')
    ss = StringHost.create(:str => 'A single double-quote " ')
    rs = StringHost.create(:str => 'Uh-oh I have a slash \\ ')
    ns = StringHost.create(:str => nil)

    results = StringHost.find_with_index('str_idx', { 'str.eq' => '"To be or not to be"'})
    assert_equal 1, results.size
    assert_equal qs.id, results.first.id

    results = StringHost.find_with_index('str_idx', { 'str.eq' => 'A single double-quote " '})
    assert_equal 1, results.size
    assert_equal ss.id, results.first.id

    results = StringHost.find_with_index('str_idx', { 'str.eq' => 'Uh-oh I have a slash \\ '})
    assert_equal 1, results.size
    assert_equal rs.id, results.first.id

    results = StringHost.find_with_index('str_idx', { 'str.eq' => nil})
    assert_equal 1, results.size
    assert_equal ns.id, results.first.id
  end

  def test_static_attributes_index
    assert_raises ActiveRest::Errors::NotStaticAttribute, "Allowed an index to be created on a nonexistant attribute" do
      RelationHost.class_eval('index "IntIndex", [:test_int], :sort => :desc')
    end
  end

  def test_index_fetch
    i = IndexHost.new
    test_num = 51 + rand(50) # Ensure we are outside the test_index_fetch_size space
    i.test_int = test_num
    i.save
    assert_equal IndexHost.find_with_index("IntIndex", test_num).first.id, i.id
    i.destroy
  end

  def test_index_fetch_size
    (1..51).each do |idx|
      i = IndexHost.new
      i.test_int = idx
      i.save
    end
    assert_equal IndexHost.find_with_index("IntIndex", {"test_int.gt" => 0}, {:size => 50}).size, 50
  end

  def test_complex_index_fetch
    i5 = ComplexIndexHost.new
    i5.test_int = 5
    i5.save
    i10 = ComplexIndexHost.new
    i10.test_int = 10
    i10.save
    i3 = ComplexIndexHost.new
    i3.test_int = 3
    i3.save
    res = ComplexIndexHost.find_with_index("test_int", "test_int.gt" => 4)
    assert_equal res.size, 2
    assert_includes res.map(&:db_id), i5.db_id
    assert_includes res.map(&:db_id), i10.db_id
  end

  def test_utc_date_secs_index_inequality
    b = IndexedTimestamps.new
    time = Time.now
    b.bonus_timestamp = time + 120 # 2 minutes in the future, just to be safe
    b.save

    timestamp_results = IndexedTimestamps.find_with_index("time_index", {"bonus_timestamp.gt" => (time + 60)}) # Use the future
    assert_equal timestamp_results.size, 1
    timestamp_results = IndexedTimestamps.find_with_index("time_index", {"bonus_timestamp.lt" => (time + 480)}) # Far in the future
    assert_equal timestamp_results.size, 1
    timestamp_results = IndexedTimestamps.find_with_index("time_index", {"bonus_timestamp.gt" => (time + 960)}) # Too far in the future
    assert_equal timestamp_results.size, 0
    timestamp_results = IndexedTimestamps.find_with_index("time_index", {"bonus_timestamp.lt" => (time - 960)}) # Too far in the past
    assert_equal timestamp_results.size, 0

    p = IndexedTimestamps.create(:bonus_timestamp => Time.at(-1))
    timestamp_results = IndexedTimestamps.find_with_index("time_index", {"bonus_timestamp.lt" => Time.at(0)})
    assert_equal timestamp_results.size, 1
    assert_equal timestamp_results.first.bonus_timestamp, Time.at(-1)
  end

  def test_compound_indexed_timestamps
     b = CompoundIndexedTimestamps.new
     time = Time.now
     b.timestamp = time
     b.int = 1
     b.save

     timestamp_results = CompoundIndexedTimestamps.find_with_index("compound_index", {"timestamp.gt" => (time - 120), "int.lt" => 2})
     assert_equal timestamp_results.size, 1
     timestamp_results = CompoundIndexedTimestamps.find_with_index("compound_index", {"timestamp.gt" => (time - 120), "int.gt" => 2})
     assert_equal timestamp_results.size, 0
   end

   def test_index_exists_with_index
     ### simple index
     IndexHost.create(:test_int => 100)
     IndexHost.create(:test_int => 200)
     IndexHost.create(:test_int => 300)
     IndexHost.create(:test_int => 300)

     # when no matching record exists
     assert_equal false, IndexHost.exists?("IntIndex", 400)
     assert_equal false, IndexHost.exists?("IntIndex", :test_int => 400)

     # when 1 matching record exists
     assert_equal true, IndexHost.exists?("IntIndex", 100)
     assert_equal true, IndexHost.exists?("IntIndex", :test_int => 100)

     # when 2 matching records exist
     assert_equal true, IndexHost.exists?("IntIndex", 300)
     assert_equal true, IndexHost.exists?("IntIndex", :test_int => 300)

     ### multi index
     MultiIndexHost.create!(:test_int_one => 100, :test_int_two => 50)
     MultiIndexHost.create!(:test_int_one => 200, :test_int_two => 50)
     MultiIndexHost.create!(:test_int_one => 300, :test_int_two => 50)
     MultiIndexHost.create!(:test_int_one => 300, :test_int_two => 100)

     # when no matching record exists
     assert_equal false, MultiIndexHost.exists?("test_ints", 100, 100)
     assert_equal false, MultiIndexHost.exists?("test_ints", :test_int_one => 100, :test_int_two => 100)

     # when 1 matching record exists
     assert_equal true, MultiIndexHost.exists?("test_ints", 100, 50)
     assert_equal true, MultiIndexHost.exists?("test_ints", :test_int_one => 100, :test_int_two => 50)

     # when 2 matching records exist
     assert_equal true, MultiIndexHost.exists?("test_ints", 300, 50)
     assert_equal true, MultiIndexHost.exists?("test_ints", :test_int_one => 300, :test_int_two => 50)

     # when 2 matching records exist, partial index value
     assert_equal true, MultiIndexHost.exists?("test_ints", :test_int_one => 300)
   end

   def test_orm_adapter_indexes
     h = OrmAdapterIndexHost.new
     h.string_one = "ONE"
     h.string_two = "TWO"
     h.save
     h2 = OrmAdapterIndexHost.new
     h.string_one = "THREE"
     h.string_two = "FOUR"
     h2.save

     assert_equal OrmAdapterIndexHost.to_adapter.find_first(:conditions => {:string_one => "ONE", :string_two => "TWO"}).db_id, h.db_id, "Could not find using OrmAdapter"
     assert_equal OrmAdapterIndexHost.to_adapter.find_all(:conditions => {:string_one => "FOOBAR"}).size, 0, "Found nonexistant object using OrmAdapter"
   end

   # test the 'all' index (as opposed to testing *all* indexes)
   def test__all__index
     ids = []
     assert_equal TestIndexAllObject.all.map(&:db_id), ids

     150.times do
       ids << TestIndexAllObject.create!(:not_really_important => "duh").db_id
     end
     assert_equal TestIndexAllObject.all.to_ids, ids[0..99]
     assert_equal TestIndexAllObject.all.next_set.to_ids, ids[100..149]
   end

   # FIXME this behaviour is odd and seems like a bug
   # def test_subclassing_find_with_index
   #   superclass_model = TestSuperclass.create!(:number => 10)
   #   subclass_model = TestSubclass.create!(:number => 10)
   #
   #   assert_equal [superclass_model], TestSuperclass.find_with_index('number', 10).to_a
   #   assert_equal [subclass_model], TestSuperclass.find_with_index('number', 10).to_a
   # end

   def index_schema
     expected = [{"name"=>"idx", "unique"=>nil, "cols"=>[{"name"=>:int, :sort=>"DESC"}, {"name"=>"id", "sort"=>"DESC"}]}]
     assert_equal expected, SimpleInHost.to_schema['indexes']
   end

   def test_pk_in_secondary_index_query
     a = SimpleInHost.create(:int => 50)
     b = SimpleInHost.create(:int => 50)
     c = SimpleInHost.create(:int => 55)
     d = SimpleInHost.create(:int => 55)

     results = SimpleInHost.find_with_index('idx', { :int => 50 })
     assert_equal 2, results.size
     assert_equal [b, a].map(&:id), results.map(&:id)

     results = SimpleInHost.find_with_index('idx', { :int => 50, :id => b.db_id })
     assert_equal 1, results.size
     assert_equal [b].map(&:id), results.map(&:id)

     results = SimpleInHost.find_with_index('idx', { :int => 50, 'id.lt' => c.db_id })
     assert_equal 2, results.size
     assert_equal [b, a].map(&:id), results.map(&:id)

     results = SimpleInHost.find_with_index('idx', { :int => 55, 'id.gt' => c.db_id })
     assert_equal 1, results.size
     assert_equal [d].map(&:id), results.map(&:id)
   end
end
