require 'test_helper'

class EnumerableResultsTest < MiniTest::Unit::TestCase
  def test_enumerable_results
    a = IndexHost.create(:test_int => 500)
    b = IndexHost.create(:test_int => 500)
    c = IndexHost.create(:test_int => 500)
    d = IndexHost.create(:test_int => 500)
    e = IndexHost.create(:test_int => 500)

    results = IndexHost.find_with_index("IntIndex", { :test_int => 500 }, :size => 2)
    assert_equal 2, results.size
    assert_equal e.id, results[0].id, "did not return e"
    assert_equal d.id, results.to_a[1].id, "did not return d"

    next_set = results.next_set
    assert_equal 2, next_set.size
    assert_equal c.id, next_set[0].id, "did not return c"
    assert_equal b.id, next_set[1].id, "did not return b"

    next_set = next_set.next_set
    assert_equal 1, next_set.to_a.size
    assert_equal a.id, next_set.to_a.first.id, "did not return a"

    results = IndexHost.find_with_index("IntIndex", { :test_int => 500 }, :size => 10)
    assert_equal 5, results.size
    assert_equal [e, d, c].map(&:id), results[0..2].map(&:id)

    results = IndexHost.find_with_index("IntIndex", { :test_int => 500 }, :size => 1)
    assert_nil results.prev, "prev is not nil"
    refute_nil results.next, "next is nil"

    results = IndexHost.find_with_index("IntIndex", { :test_int => 500 }, { :size => 1, :token => results.next })
    refute_nil results.prev, "prev is nil"
    refute_nil results.next, "next is nil"

    results = IndexHost.find_with_index("IntIndex", { :test_int => 500 }, :size => 4)
    results = IndexHost.find_with_index("IntIndex", { :test_int => 500 }, { :size => 4, :token => results.next })
    refute_nil results.prev, "prev is nil"
    assert_nil results.next, "next is not nil"
  end

  def test_enumerable_results_from_array
    a = IndexHost.create(:test_int => 9000)
    b = IndexHost.create(:test_int => 9000)
    c = IndexHost.create(:test_int => 9000)
    d = IndexHost.create(:test_int => 9000)
    e = IndexHost.create(:test_int => 9000)
    results = IndexHost.find_with_index("IntIndex", { :test_int => 9000 }, :size => 5)
    results_array = results.map {|r| r}
    e = ActiveRest::EnumerableResults.new(results_array)

    assert_equal e.size, 5
  end

  def test_map_children
    child1 = ParentModel::NamespacedModel::DeepNamespacedModel.create!(:gyp => 'qqq')
    child2 = OtherParentModel::OtherNamespacedModel.create!

    parent1 = ParentModel.create!(:foo => '123', :namespaced_polymorphic_has_one => child1)
    parent2 = ParentModel.create!(:foo => '123', :namespaced_polymorphic_has_one => child2)
    parent3 = ParentModel.create!(:foo => '123')
    parent_ids = [parent3, parent2, parent1].map(&:db_id)

    assert_equal ParentModel.find_with_index('foo', '123').to_ids, parent_ids
    assert_equal ParentModel.find_with_index('foo', '123').map_children(:namespaced_polymorphic_has_one).to_ids, [nil, child2.db_id, child1.db_id]
    assert_equal ParentModel.find_with_index('foo', '123').map_children(:namespaced_polymorphic_has_one).to_map.keys, [child2, child1].map(&:db_id)
  end

  def test_includes_shallow
    child1 = ParentModel::NamespacedModel::DeepNamespacedModel.create!(:gyp => 'qqq')
    child2 = OtherParentModel::OtherNamespacedModel.create!

    parent1 = ParentModel.create!(:foo => '123', :namespaced_polymorphic_has_one => child1)
    parent2 = ParentModel.create!(:foo => '123', :namespaced_polymorphic_has_one => child2)
    parent3 = ParentModel.create!(:foo => '123')
    parent_ids = [parent3, parent2, parent1].map(&:db_id)

    assert_equal ParentModel.find_with_index('foo', '124').includes(:invalid).to_ids, []
    assert_equal ParentModel.find_with_index('foo', '124').includes(:invalid, :namespaced_polymorphic_has_one).to_ids, []

    assert_equal ParentModel.find_with_index('foo', '123').includes(:invalid).to_ids, parent_ids
    assert_equal ParentModel.find_with_index('foo', '123').includes(:invalid, :namespaced_polymorphic_has_one).to_ids, parent_ids
    assert_equal ParentModel.find_with_index('foo', '123').includes(:namespaced_polymorphic_has_one).to_map.keys, parent_ids
  end

  def test_includes_deep
    child1 = ParentModel::NamespacedModel::DeepNamespacedModel.create!(:gyp => 'qqq')
    child2 = OtherParentModel::OtherNamespacedModel.create!

    parent1 = ParentModel.create!(:foo => '123', :namespaced_polymorphic_has_one => child1)
    parent2 = ParentModel.create!(:foo => '123', :namespaced_polymorphic_has_one => child2)
    parent3 = ParentModel.create!(:foo => '123')
    parent_ids = [parent3, parent2, parent1].map(&:db_id)

    assert_equal ParentModel.find_with_index('foo', '124').includes(:invalid => :unknown).to_ids, []

    assert_equal ParentModel.find_with_index('foo', '123').includes(:invalid => :unknown).to_ids, parent_ids
    assert_equal ParentModel.find_with_index('foo', '123').includes(:invalid => :unknown, :namespaced_polymorphic_has_one => [:user, :invalid]).to_ids, parent_ids
  end

  def test_batch_multiget
    ids = []
    (1..1000).each do |i|
      ids << IndexHost.create(:test_int => i).db_id
    end
    results = ActiveRest::EnumerableResults.new(ids)
    assert_equal results.size, 1000
    assert_equal results.map(&:test_int), (1..1000).to_a
  end
end
