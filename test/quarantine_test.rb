require 'test_helper'

class QuarantineTest < MiniTest::Unit::TestCase
  def test_quarantining
    a = QuarantinedModel.create({ :name => 'Fox' })
    b = QuarantinedModel.create({ :name => 'Fish' })

    # finders (pre-quarantine)
    assert_equal a, QuarantinedModel.find(a.id)
    assert_equal b, QuarantinedModel.find(b.id)
    assert_equal [a, b], QuarantinedModel.find([a.id, b.id])

    # === quarantine ===
    a.quarantine!

    # status
    assert a.quarantined?
    refute b.quarantined?

    # primary index finders
    assert_nil QuarantinedModel.find(a.id)
    assert_equal a, QuarantinedModel.find(a.id, :with_quarantined => true)
    assert_equal b, QuarantinedModel.find(b.id)
    assert_equal b, QuarantinedModel.find(b.id, :with_quarantined => true)
    assert_equal [b], QuarantinedModel.find([a.id, b.id])
    assert_equal [a, b], QuarantinedModel.find([a.id, b.id], :with_quarantined => true)

    # secondary index finders
    assert_empty QuarantinedModel.find_with_index('name', a.name)
    assert_equal [a], QuarantinedModel.find_with_index('name', { :name => a.name }, { :with_quarantined => true }).to_a
    assert_equal [b], QuarantinedModel.find_with_index('name', 'name.ge' => 'F').to_a
    assert_equal [a, b], QuarantinedModel.find_with_index('name', { 'name.ge' => 'F' }, { :with_quarantined => true }).to_a

    # === unquarantining ===
    a.unquarantine!

    # status
    refute a.quarantined?
    refute b.quarantined?

    # primary index finders
    assert_equal a, QuarantinedModel.find(a.id)
    assert_equal b, QuarantinedModel.find(b.id)
    assert_equal [a, b], QuarantinedModel.find([a.id, b.id])

    # secondary index finders
    assert_equal [a], QuarantinedModel.find_with_index('name', a.name).to_a
    assert_equal [a, b], QuarantinedModel.find_with_index('name', 'name.ge' => 'F').to_a

    # === destroying ===
    a.quarantine!

    # status
    assert a.quarantined?
    refute b.quarantined?

    # destroy
    assert a.destroy
    assert_nil QuarantinedModel.find(a.id, :with_quarantined => true)
    assert_raises(ActiveRest::Errors::NotFoundError) { a.quarantined? }

    # primary index finders
    assert_nil QuarantinedModel.find(a.id)
    assert_nil QuarantinedModel.find(a.id, :with_quarantined => true)
    assert_equal [b], QuarantinedModel.find([a.id, b.id])
    assert_equal [b], QuarantinedModel.find([a.id, b.id], :with_quarantined => true)

    # secondary index finders
    assert_empty QuarantinedModel.find_with_index('name', a.name)
    assert_empty QuarantinedModel.find_with_index('name', { :name => a.name }, { :with_quarantined => true }).to_a
    assert_equal [b], QuarantinedModel.find_with_index('name', 'name.ge' => 'F').to_a
    assert_equal [b], QuarantinedModel.find_with_index('name', { 'name.ge' => 'F' }, { :with_quarantined => true }).to_a
  end

  def test_quarantine_has_many
    # quarantines should cascade to all quarantinable children
    host = QuarantinedHasManyHost.create!
    quarantinable_child = QuarantinedHasManyTarget.create!(:parent => host)
    normal_child = NonQuarantinedHasManyTarget.create!(:parent => host)
    host.quarantine!
    assert quarantinable_child.quarantined?, 'quarantine did not cascade'
    assert_equal normal_child, NonQuarantinedHasManyTarget.find!(normal_child.id)

    # destroy should then remove the quarantined children
    host.destroy
    assert_nil QuarantinedHasManyTarget.find(quarantinable_child.id, :with_quarantined => true)
    assert_nil NonQuarantinedHasManyTarget.find(normal_child.id)

    # quarantines should cascade to all quarantinable children
    # (when > Relations::HasMany::DEFAULT_HAS_MANY_RELATION_GET_SIZE quarantinable childen)
    host = QuarantinedHasManyHost.create!
    silence_warnings do
      ActiveRest::Relations::HasMany.module_eval do
        const_set 'DEFAULT_HAS_MANY_RELATION_GET_SIZE', 5
      end
    end
    quarantinable_children = []
    (ActiveRest::Relations::HasMany::DEFAULT_HAS_MANY_RELATION_GET_SIZE + 1).times do
      quarantinable_children << QuarantinedHasManyTarget.create!(:parent => host)
    end
    normal_child = NonQuarantinedHasManyTarget.create!(:parent => host)
    assert_equal 5, host.quarantinable_targets.size
    assert_equal 1, host.quarantinable_targets.next_set.size
    host.quarantine!
    assert_equal [], QuarantinedHasManyTarget.find(quarantinable_children.map(&:id)).to_a
    assert_equal quarantinable_children, QuarantinedHasManyTarget.find(quarantinable_children.map(&:id), :with_quarantined => true).to_a
    assert quarantinable_children.all?(&:quarantined?), 'quarantine did not cascade'
    assert_equal normal_child, NonQuarantinedHasManyTarget.find!(normal_child.id)

    # unquarantine
    host.unquarantine!
    assert_equal quarantinable_children.map(&:id), QuarantinedHasManyTarget.find(quarantinable_children.map(&:id)).to_a.map(&:id)
    assert quarantinable_children.none?(&:quarantined?)
    assert_equal normal_child, NonQuarantinedHasManyTarget.find!(normal_child.id)

    # destroy should then remove the quarantined children
    host.quarantine!
    host.destroy
    assert_equal [], QuarantinedHasManyTarget.find(quarantinable_children.map(&:id)).to_a
    assert_equal [], QuarantinedHasManyTarget.find(quarantinable_children.map(&:id), :with_quarantined => true).to_a
    assert_nil NonQuarantinedHasManyTarget.find(normal_child.id)
  end
end
