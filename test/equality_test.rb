require 'test_helper'

class EqualityTest < MiniTest::Unit::TestCase
  def test_record_equality
    # same exact object
    a = create_dummy_object
    assert (a == a) == true, "same exact objects should be equal"

    # same exact object, with changes
    a.test_data_one = "Foo"
    assert (a == a) == true, "same exact objects with changes should be equal"

    # comparing with nil (no exception)
    assert (a == nil) == false, "with nil should not be equal"

    # comparing with some random object
    assert (a == Object.new) == false, "random object should not be equal"

    # different object, same id
    b = TestHarnessObject.find!(a.id)
    assert (a == b) == true, "diff. object, same id, shoud be equal"

    # different object, with changes
    b = TestHarnessObject.find!(a.id)
    b.test_data_one = "Bar"
    assert (a == b) == true, "diff. object, same id with changes, should be equal"

    # new record, same exact object
    c = TestHarnessObject.new(:test_data_one => "test data one")
    assert (c == c) == true,  "new record, exact same object, should be equal"

    # 2 new records
    d = TestHarnessObject.new(:test_data_one => "test data one")
    assert (c == d) == false, "2 new records, should not be equal"

    # 1 new record, 1 saved
    assert (c == a) == false, "new record, should not be equal"

    # unique
    assert ([a.reloaded, a, b, c].uniq == [a, c]) == true, "uniq should be equal"
  end

  def test_hash_equality
    # same exact object
    a = create_dummy_object
    assert (a.hash == a.hash) == true, "same exact objects should be equal"

    # same exact object, with changes
    a.test_data_one = "Foo"
    assert (a.hash == a.hash) == true, "same exact objects with changes should be equal"

    # comparing with nil (no exception)
    assert (a.hash == nil.hash) == false, "with nil should not be equal"

    # comparing with some random object
    assert (a.hash == Object.new.hash) == false, "random object should not be equal"

    # different object, same id
    b = TestHarnessObject.find!(a.id)
    assert (a.hash == b.hash) == true, "diff. object, same id, shoud be equal"

    # different object, with changes
    b = TestHarnessObject.find!(a.id)
    b.test_data_one = "Bar"
    assert (a.hash == b.hash) == true, "diff. object, same id with changes, should be equal"

    # new record, same exact object
    c = TestHarnessObject.new(:test_data_one => "test data one")
    assert (c.hash == c.hash) == true,  "new record, exact same object, should be equal"

    # 2 new records
    d = TestHarnessObject.new(:test_data_one => "test data one")
    assert (c.hash == d.hash) == false, "2 new records, should not be equal"

    # 1 new record, 1 saved
    assert (c.hash == a.hash) == false, "new record, should not be equal"
  end

  def test_eql_equality
    # same exact object
    a = create_dummy_object
    assert (a.eql? a) == true, "same exact objects should be equal"

    # same exact object, with changes
    a.test_data_one = "Foo"
    assert (a.eql? a) == true, "same exact objects with changes should be equal"

    # comparing with nil (no exception)
    assert (a.eql? nil) == false, "with nil should not be equal"

    # comparing with some random object
    assert (a.eql? Object.new) == false, "random object should not be equal"

    # different object, same id
    b = TestHarnessObject.find!(a.id)
    assert (a.eql? b) == true, "diff. object, same id, shoud be equal"

    # different object, with changes
    b = TestHarnessObject.find!(a.id)
    b.test_data_one = "Bar"
    assert (a.eql? b) == true, "diff. object, same id with changes, should be equal"

    # new record, same exact object
    c = TestHarnessObject.new(:test_data_one => "test data one")
    assert (c.eql? c) == true,  "new record, exact same object, should be equal"

    # 2 new records
    d = TestHarnessObject.new(:test_data_one => "test data one")
    assert (c.eql? d) == false, "2 new records, should not be equal"

    # 1 new record, 1 saved
    assert (c.eql? a) == false, "new record, should not be equal"
  end

  def test_enumerable_results_record_equality
    a = IndexHost.create(:test_int => 10)
    b = IndexHost.create(:test_int => 10)
    c = IndexHost.create(:test_int => 20)
    d = IndexHost.create(:test_int => 20)
    e = IndexHost.create(:test_int => 20)
    results = IndexHost.find_with_index("IntIndex", 10)

    # another enumerable results, that are the same
    comparison = IndexHost.find_with_index("IntIndex", 10)
    assert (results == comparison) == true, "same enumerable results should be equal"

    # another enumerable results, but diff
    comparison = IndexHost.find_with_index("IntIndex", 20)
    assert (results == comparison) == false, "diff enumerable results should not be equal"

    # empty results
    empty_results = IndexHost.find_with_index("IntIndex", 999)
    comparison = IndexHost.find_with_index("IntIndex", 999)
    assert (empty_results == comparison) == true, "empty results should be equal"

    # empty Array
    empty_results = IndexHost.find_with_index("IntIndex", 999)
    comparison = []
    assert (empty_results == comparison) == true, "empty results, an Array should be equal"

    # an Array of records, same records, same order
    comparison = IndexHost.find_with_index("IntIndex", 10).to_a
    assert (results == comparison) == true, "an array, same records same order, should be equal"

    # an Array of records, same records, diff order
    comparison = IndexHost.find_with_index("IntIndex", 10).to_a.reverse
    assert (results == comparison) == false, "an array, same records diff order, should not be equal"

    # an Array of records, diff records
    comparison = IndexHost.find_with_index("IntIndex", 20).to_a
    assert (results == comparison) == false, "an array, diff records, should not be equal"

    # an Array of random objects
    comparison = [Object.new, 1, 2]
    assert (results == comparison) == false, "an array of random objects should not be equal"

    # an empty Hash
    comparison = {}
    assert (results == comparison) == false, "an empty Hash should not be equal"

    # an non-enumerable thing, like a random object
    comparison = Object.new
    assert (results == comparison) == false, "a random object should not be equal"

    # nil
    comparison = nil
    assert (results == nil) == false, "nil should not be equal"

    # unique
    assert (ActiveRest::EnumerableResults.new([a, a, b]).uniq == [a, b]) == true, "uniq should be equal"
  end

  def test_enumerable_results_hash_equality
    a = IndexHost.create(:test_int => 10)
    b = IndexHost.create(:test_int => 10)
    c = IndexHost.create(:test_int => 20)
    d = IndexHost.create(:test_int => 20)
    e = IndexHost.create(:test_int => 20)
    results = IndexHost.find_with_index("IntIndex", 10)

    # another enumerable results, that are the same
    comparison = IndexHost.find_with_index("IntIndex", 10)
    assert (results.hash == comparison.hash) == true, "same enumerable results should be equal"

    # another enumerable results, but diff
    comparison = IndexHost.find_with_index("IntIndex", 20)
    assert (results.hash == comparison.hash) == false, "diff enumerable results should not be equal"

    # empty results
    empty_results = IndexHost.find_with_index("IntIndex", 999)
    comparison = IndexHost.find_with_index("IntIndex", 999)
    assert (empty_results.hash == comparison.hash) == true, "empty results should be equal"

    # empty Array
    empty_results = IndexHost.find_with_index("IntIndex", 999)
    comparison = []
    assert (empty_results.hash == comparison.hash) == true, "empty results, an Array should be equal"

    # an Array of records, same records, same order
    comparison = IndexHost.find_with_index("IntIndex", 10).to_a
    assert (results.hash == comparison.hash) == true, "an array, same records same order, should be equal"

    # an Array of records, same records, diff order
    comparison = IndexHost.find_with_index("IntIndex", 10).to_a.reverse
    assert (results.hash == comparison.hash) == false, "an array, same records diff order, should not be equal"

    # an Array of records, diff records
    comparison = IndexHost.find_with_index("IntIndex", 20).to_a
    assert (results.hash == comparison.hash) == false, "an array, diff records, should not be equal"

    # an Array of random objects
    comparison = [Object.new, 1, 2]
    assert (results.hash == comparison.hash) == false, "an array of random objects should not be equal"

    # an empty Hash
    comparison = {}
    assert (results.hash == comparison.hash) == false, "an empty Hash should not be equal"

    # an non-enumerable thing, like a random object
    comparison = Object.new
    assert (results.hash == comparison.hash) == false, "a random object should not be equal"

    # nil
    comparison = nil
    assert (results.hash == nil.hash) == false, "nil should not be equal"
  end

  def test_enumerable_results_eql_equality
    a = IndexHost.create(:test_int => 10)
    b = IndexHost.create(:test_int => 10)
    c = IndexHost.create(:test_int => 20)
    d = IndexHost.create(:test_int => 20)
    e = IndexHost.create(:test_int => 20)
    results = IndexHost.find_with_index("IntIndex", 10)

    # another enumerable results, that are the same
    comparison = IndexHost.find_with_index("IntIndex", 10)
    assert (results.eql? comparison) == true, "same enumerable results should be equal"

    # another enumerable results, but diff
    comparison = IndexHost.find_with_index("IntIndex", 20)
    assert (results.eql? comparison) == false, "diff enumerable results should not be equal"

    # empty results
    empty_results = IndexHost.find_with_index("IntIndex", 999)
    comparison = IndexHost.find_with_index("IntIndex", 999)
    assert (empty_results.eql? comparison) == true, "empty results should be equal"

    # empty Array
    empty_results = IndexHost.find_with_index("IntIndex", 999)
    comparison = []
    assert (empty_results.eql? comparison) == true, "empty results, an Array should be equal"

    # an Array of records, same records, same order
    comparison = IndexHost.find_with_index("IntIndex", 10).to_a
    assert (results.eql? comparison) == true, "an array, same records same order, should be equal"

    # an Array of records, same records, diff order
    comparison = IndexHost.find_with_index("IntIndex", 10).to_a.reverse
    assert (results.eql? comparison) == false, "an array, same records diff order, should not be equal"

    # an Array of records, diff records
    comparison = IndexHost.find_with_index("IntIndex", 20).to_a
    assert (results.eql? comparison) == false, "an array, diff records, should not be equal"

    # an Array of random objects
    comparison = [Object.new, 1, 2]
    assert (results.eql? comparison) == false, "an array of random objects should not be equal"

    # an empty Hash
    comparison = {}
    assert (results.eql? comparison) == false, "an empty Hash should not be equal"

    # an non-enumerable thing, like a random object
    comparison = Object.new
    assert (results.eql? comparison) == false, "a random object should not be equal"

    # nil
    comparison = nil
    assert (results.eql? nil) == false, "nil should not be equal"
  end

  def test_case_equality
    assert (TestHarnessObject === create_dummy_object) == true
    assert (ActiveRest::Base === create_dummy_object) == true
    assert (Object === create_dummy_object) == true
    assert (Fixnum === create_dummy_object) == false
    assert (TestHarnessObject === TestHarnessProxyObject.new(create_dummy_object)) == true
  end
end
