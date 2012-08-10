require 'test_helper'

class RelationTest < MiniTest::Unit::TestCase
  def test_has_many
    t = HasManyTarget.new
    t2 = HasManyTarget.new
    h = HasManyHost.new
    h.save
    t.parent = h
    t2.parent = h
    t.save
    t2.save
    assert_equal h.targets.size, 2, "Has many relation failed: size"
    assert_includes h.targets.map { |t| t.id }, t2.id, "Has many relation failed to include at least one object."
    assert_includes h.targets.map { |t| t.id }, t.id, "Has many relation failed to include at least one object."
  end

  def test_has_many_caching
    host = HasManyHost.create!

    # nothing cached, set something directly
    host.instance_variable_set(:"@targets", ['t'])
    assert_equal ['t'], host.targets.to_a

    # create a real record
    target = HasManyTarget.create!(:parent => host)
    assert_equal ['t'], host.targets.to_a
    assert_equal [target], host.targets(2).to_a

    #
    #
    #

    host = HasManyHost.create!

    # nothing cached, set something directly
    assert_equal [], host.targets.to_a
    host.instance_variable_set(:"@targets", ['t'])
    assert_equal ['t'], host.targets.to_a

    # create a real record
    target = HasManyTarget.create!(:parent => host)
    assert_equal ['t'], host.targets.to_a
    assert_equal [target], host.targets(2).to_a
  end

  def test_has_one_nil
    t = HasManyTarget.new
    h = HasManyHost.new
    h.save
    t.parent = h
    t.save
    assert_equal t.parent_id, h.db_id, "Has one failed in testing nil"
    t.parent = nil
    t.save
    t2 = HasManyTarget.find(t.id)
    assert_equal t2.parent, nil, "assigning a nil has_one relation failed."
    assert_equal t2.parent_id, nil, "assigning a nil has_one relation failed to nil the id field properly"
  end

  def test_has_one_cascade_save
    # existing host, new child
    parent = HasOneHost.create!
    parent.child = HasOneChild.new
    parent.save!
    refute_nil parent.reloaded.child

    # new host, new child
    parent = HasOneHost.new(:child => HasOneChild.new)
    parent.save!
    parent = parent.reloaded
    refute_nil parent.child

    # existing host, existing child, changing to new child
    existing_child = parent.child
    parent.child = HasOneChild.new
    parent.save!
    parent = parent.reloaded
    refute_equal existing_child, parent.child
    refute_nil parent.child

    # existing host, existing child, updating child
    existing_child = parent.child
    existing_child.foo = 'new'
    parent.save!
    parent = parent.reloaded
    assert_equal 'new', parent.child.foo
  end

  def test_has_many_json
    t = HasManyTarget.new
    t2 = HasManyTarget.new
    h = HasManyHost.new
    h.save
    t.parent = h
    t2.parent = h
    t.save
    t2.save
    h_json = h.to_json(:include => {:targets => {:only => [:parent_id]}})
    h_hash = JSON.parse(h_json) # Validates too!
    assert_includes h_hash["targets"].first.keys, "parent_id"
    assert_equal h_hash["targets"].length, 2
    assert_equal h_hash["targets"].first["parent_id"], h.db_id
  end

  def test_destroy_has_many
    # simple case
    t = HasManyTarget.new
    t2 = HasManyTarget.new
    h = HasManyHost.new
    h.save
    t.parent = h
    t2.parent = h
    t.save
    t2.save
    assert_equal h.targets.size, 2, "Has many relation failed: size"
    h.destroy
    assert_equal HasManyTarget.find(t.id), nil, "Has Many destruction failed."
    assert_equal HasManyTarget.find(t2.id), nil, "Has Many destruction failed."

    # case when more than records than defined by
    # Relations::HasMany::DEFAULT_HAS_MANY_RELATION_GET_SIZE
    # (which is nil by default, using ST9s 100 default limit)
    host = HasManyHost.create!
    silence_warnings do
      ActiveRest::Relations::HasMany.module_eval do
        const_set 'DEFAULT_HAS_MANY_RELATION_GET_SIZE', 5
      end
    end
    targets = []
    (ActiveRest::Relations::HasMany::DEFAULT_HAS_MANY_RELATION_GET_SIZE + 1).times do
      targets << HasManyTarget.create!(:parent => host)
    end
    assert_equal 5, host.targets.size
    assert_equal 1, host.targets.next_set.size
    host.destroy
    assert_equal [], HasManyTarget.find(targets.map(&:id)).to_a
  end

  def test_has_many_through
    t =  RelationTarget.new
    t2 = RelationTarget.new
    h = RelationHost.new
    h2 = RelationHost.new
    th = HasManyThroughHost.new
    th.save
    h.parent = th
    h2.parent = th
    h.save
    h2.save
    t.parent = h
    t2.parent = h2
    t.save
    t2.save
    assert_equal th.relation_targets.size, 2, "Has Many Through Relation Failed"
  end

  def test_relations
    r = RelationTarget.create
    rh = RelationHost.new
    rh.relation_target = r
    assert_equal rh.relation_target, r, "Could not set relation target"
    assert_equal rh.relation_target_id, r.db_id, "Incorrectly set relation target ID"
  end

  def test_relation_classes
    r = RelationTarget.create
    r2 = RelationTarget.create
    rh = RelationHost.new
    rh.relation_target = r
    rh.relation_target_two = r2

    assert_equal rh.relation_target_two, r2, "Could not set overridden class on relation target"
    assert_equal rh.relation_target, r, "Could not set relation target"
  end

  def test_relation_deserialization
    r = RelationTarget.create
    r2 = RelationTarget.create
    rh = RelationHost.new
    rh.relation_target = r
    rh.relation_target_two = r2
    rh.save

    rh2 = RelationHost.find(rh.id)

    assert_equal rh2.relation_target_id, r.db_id
    assert_equal rh2.relation_target_two_id, r2.db_id
    assert_equal rh2.relation_target.id, r.id
    assert_equal rh2.relation_target_two.id, r2.id
  end

  def test_relation_typing
    rh = RelationHost.new
    assert_raises ActiveRest::Errors::InvalidAssociation, "Did not raise a type exception on invalid type assignment" do
      rh.relation_target = RelationHost.new
    end
  end

  def test_include
    t =  RelationTarget.new
    t2 = RelationTarget.new
    h = RelationHost.new
    h2 = RelationHost.new
    th = HasManyThroughHost.new
    th.save
    h.parent = th
    h2.parent = th
    h.save
    h2.save
    t.parent = h
    t2.parent = h2
    h.relation_target = t
    h2.relation_target = t2
    t.save
    t2.save
    h.save
    h2.save
    hosts_including_targets = th.relation_hosts.includes(:relation_target)
    assert_equal hosts_including_targets.first.relation_target_id, hosts_including_targets.first.relation_target.db_id
    assert_equal hosts_including_targets[1].relation_target_id, hosts_including_targets[1].relation_target.db_id
  end

  def test_polymorphic_type
    im = ImageMedia.create
    vm = VideoMedia.create

    pmh_image = PolymorphicHost.create(:media => im)
    pmh_video = PolymorphicHost.create(:media => vm)

    assert_equal pmh_image.media.media_type, 'image'
    assert_equal pmh_video.media.media_type, 'video'

    results = PolymorphicHost.find_with_index('media_id', im.db_id)
    assert_equal 1, results.size
    assert_equal im.db_id, results.first.media.db_id

    results = PolymorphicHost.find_with_index('media_id', vm.db_id)
    assert_equal 1, results.size
    assert_equal vm.db_id, results.first.media.db_id

    assert_raises ActiveRest::Errors::InvalidAssociation, 'did not raise InvalidAssociation' do
      PolymorphicHost.create(:media => 'I am a string')
    end
  end

  def test_cascade_config
    # enabled
    ActiveRest::Config.config = CONFIG.merge('allow_cascades' => true)
    assert ActiveRest::Config.allow_cascades?

    # cascade destroy works
    record = HasManyHost.create!
    assert record.destroy

    # normal destroy works
    record = TestHarnessObject.create!
    assert record.destroy

    # cascade quarantine works
    record = QuarantinedHasManyHost.create!
    assert record.quarantine!

    # normal quarantine works
    record = QuarantinedModel.create!
    assert record.quarantine!

    # no key present
    ActiveRest::Config.config = CONFIG.except('allow_cascades')
    refute ActiveRest::Config.allow_cascades?

    # key present, but false
    ActiveRest::Config.config = CONFIG.merge('allow_cascades' => false)
    refute ActiveRest::Config.allow_cascades?

    # cascade destroy raises exception
    record = HasManyHost.create!
    assert_raises(ActiveRest::Errors::CascadeError) { record.destroy }

    # normal destroy works
    record = TestHarnessObject.create!
    assert record.destroy

    # cascade quarantine raises exception
    record = QuarantinedHasManyHost.create!
    assert_raises(ActiveRest::Errors::CascadeError) { record.quarantine! }

    # normal quarantine works
    record = QuarantinedModel.create!
    assert record.quarantine!

    # enabled
    ActiveRest::Config.config = CONFIG.merge('allow_cascades' => true)
    assert ActiveRest::Config.allow_cascades?

  ensure
    # restore original settings
    ActiveRest::Config.config = CONFIG
  end

  def test_recursive_cascade_config
    ActiveRest::Config.config = CONFIG.merge('allow_cascades' => true)
    assert ActiveRest::Config.allow_cascades?

    host = HasManyHost.create!
    child = HasManyTarget.create!(:parent => host)
    child_child = HasManyTargetTarget.create!(:parent => child)
    child_child_child = HasManyTargetTargetTarget.create!(:parent => child_child)

    host.destroy
    refute HasManyHost.find(host.id)
    refute HasManyTarget.find(child.id)
    refute HasManyTargetTarget.find(child_child.id)
    refute HasManyTargetTargetTarget.find(child_child_child.id)
  ensure
    ActiveRest::Config.config = CONFIG
  end

  def test_cascade_destroy_with_callbacks
    ActiveRest::Config.config = CONFIG.merge('allow_cascades' => true)
    assert ActiveRest::Config.allow_cascades?

    host = HasManyDependentDestroyHost.create!
    child = HasManyDependentDestroyTarget.create!(:parent => host)
    child_child = HasManyDependentDestroyTargetTarget.create!(:parent => child)
    assert_equal HasManyDependentDestroyTargetTarget.after_destroy_called, 0
    host.destroy
    refute HasManyDependentDestroyHost.find(host.id)
    refute HasManyDependentDestroyTarget.find(child.id)
    refute HasManyDependentDestroyTargetTarget.find(child_child.id)
    assert_equal HasManyDependentDestroyTargetTarget.after_destroy_called, 1

  end
end
