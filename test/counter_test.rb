require 'test_helper'

class CounterTest < MiniTest::Unit::TestCase
  def test_simple_boolean_count
    assert_equal 0, SimpleBooleanCountHost.count("by_cool").size

    u0 = SimpleBooleanCountHost.new
    u0.is_cool = true
    u0.save

    assert_equal [{"is_cool" => true, "count" => 1}], SimpleBooleanCountHost.count("by_cool").counts
    assert_equal [{"is_cool" => true, "count" => 1}], SimpleBooleanCountHost.count("by_cool", true).counts
    assert_equal [], SimpleBooleanCountHost.count("by_cool", false).counts

    u1 = SimpleBooleanCountHost.new
    u1.is_cool = false
    u1.save

    assert_equal [{"is_cool" => true, "count" => 1}, {"is_cool" => false, "count" => 1}], SimpleBooleanCountHost.count("by_cool").counts
    assert_equal [{"is_cool" => true, "count" => 1}], SimpleBooleanCountHost.count("by_cool", true).counts
    assert_equal [{"is_cool" => false, "count" => 1}], SimpleBooleanCountHost.count("by_cool", false).counts

    u1.is_cool = true
    u1.save

    assert_equal [{"is_cool" => true, "count" => 2}], SimpleBooleanCountHost.count("by_cool").counts
    assert_equal [{"is_cool" => true, "count" => 2}], SimpleBooleanCountHost.count("by_cool", true).counts
    assert_equal [], SimpleBooleanCountHost.count("by_cool", false).counts

    u0.destroy

    assert_equal [{"is_cool" => true, "count" => 1}], SimpleBooleanCountHost.count("by_cool").counts
    assert_equal [{"is_cool" => true, "count" => 1}], SimpleBooleanCountHost.count("by_cool", true).counts
    assert_equal [], SimpleBooleanCountHost.count("by_cool", false).counts

    u1.destroy

    assert_equal [], SimpleBooleanCountHost.count("by_cool").counts
    assert_equal [], SimpleBooleanCountHost.count("by_cool", true).counts
    assert_equal [], SimpleBooleanCountHost.count("by_cool", false).counts
  end

  def test_composite_count
    assert_equal 0, CompositeCountHost.count("by_attr1").size
    assert_equal 0, CompositeCountHost.count("by_attr2").size
    assert_equal 0, CompositeCountHost.count("by_attr3").size
    assert_equal 0, CompositeCountHost.count("by_all_attrs").size

    u0 = CompositeCountHost.new
    u0.attr1 = "foo"
    u0.attr2 = true
    u0.attr3 = "ONE"
    u0.save

    assert_equal CompositeCountHost.count("by_attr1").counts, [{"attr1"=>"foo", "count"=>1}]
    assert_equal CompositeCountHost.count("by_attr2").counts, [{"attr2"=>true, "count"=>1}]
    assert_equal CompositeCountHost.count("by_attr3").counts, [{"attr3"=>"ONE", "count"=>1}]
    assert_equal CompositeCountHost.count("by_all_attrs").counts, [{"attr1"=>"foo", "attr2"=>true, "attr3"=>"ONE", "count"=>1}]

    u1 = CompositeCountHost.new
    u1.attr1 = "bar"
    u1.attr2 = false
    u1.attr3 = "TWO"
    u1.save

    assert_equal CompositeCountHost.count("by_attr1").counts, [{"attr1"=>"foo", "count"=>1}, {"attr1"=>"bar", "count"=>1}]
    assert_equal CompositeCountHost.count("by_attr2").counts, [{"attr2"=>true, "count"=>1}, {"attr2"=>false, "count"=>1}]
    assert_equal CompositeCountHost.count("by_attr3").counts, [{"attr3"=>"TWO", "count"=>1}, {"attr3"=>"ONE", "count"=>1}]
    assert_equal CompositeCountHost.count("by_all_attrs").counts, [{"attr1"=>"foo", "attr2"=>true, "attr3"=>"ONE", "count"=>1}, {"attr1"=>"bar", "attr2"=>false, "attr3"=>"TWO", "count"=>1}]

    u1.attr1 = "foo"
    u1.save

    assert_equal CompositeCountHost.count("by_attr1").counts, [{"attr1"=>"foo", "count"=>2}]
    assert_equal CompositeCountHost.count("by_attr2").counts, [{"attr2"=>true, "count"=>1}, {"attr2"=>false, "count"=>1}]
    assert_equal CompositeCountHost.count("by_attr3").counts, [{"attr3"=>"TWO", "count"=>1}, {"attr3"=>"ONE", "count"=>1}]
    assert_equal CompositeCountHost.count("by_all_attrs").counts, [{"attr1"=>"foo", "attr2"=>true, "attr3"=>"ONE", "count"=>1}, {"attr1"=>"foo", "attr2"=>false, "attr3"=>"TWO", "count"=>1}]

    u0.attr2 = false
    u0.save

    assert_equal CompositeCountHost.count("by_attr1").counts, [{"attr1"=>"foo", "count"=>2}]
    assert_equal CompositeCountHost.count("by_attr2").counts, [{"attr2"=>false, "count"=>2}]
    assert_equal CompositeCountHost.count("by_attr3").counts, [{"attr3"=>"TWO", "count"=>1}, {"attr3"=>"ONE", "count"=>1}]
    assert_equal CompositeCountHost.count("by_all_attrs").counts, [{"attr1"=>"foo", "attr2"=>false, "attr3"=>"TWO", "count"=>1}, {"attr1"=>"foo", "attr2"=>false, "attr3"=>"ONE", "count"=>1}]

    u0.destroy
    u1.destroy

    assert_equal CompositeCountHost.count("by_attr1").counts, []
    assert_equal CompositeCountHost.count("by_attr2").counts, []
    assert_equal CompositeCountHost.count("by_attr3").counts, []
    assert_equal CompositeCountHost.count("by_all_attrs").counts, []
  end
end
