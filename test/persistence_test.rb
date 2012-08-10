require 'test_helper'

class PersistenceTest < MiniTest::Unit::TestCase
  def test_object_creation
    t = TestHarnessObject.create(:test_data_one => "test data one")
    assert_equal "test data one", t.test_data_one, "Created object does not have the correct attributes assigned"
  end

  def test_object_fetch
    t = create_dummy_object
    t2 = TestHarnessObject.find(t.id)
    assert_equal t2.test_data_one, t.test_data_one, "Deserialized object does not have the same attributes as saved object"
    assert_empty t2.changed_attributes, "Dirty attributes not cleared on deserialization"
  end

  def test_update_on_save
    t = create_dummy_object
    t.test_data_one = "test data two"
    t.save

    t2 = TestHarnessObject.find(t.id)

    assert_equal t.test_data_one, t2.test_data_one, "Saved object's attributes were not updated"
  end

  def test_persisted_state
    record = TestHarnessObject.new(:test_data_one => "test data one")

    assert record.new_record?, "#new_record? is false, should be true"
    assert !record.persisted?, "#persisted? is true, should be false"

    record.save

    assert !record.new_record?, "#new_record? is true, should be false"
    assert record.persisted?, "#persisted? is false, should be true"
  end

  def test_reloading
    record = create_dummy_object
    reloaded_record = record.reloaded
    assert_equal reloaded_record, record
    refute_equal reloaded_record.object_id, record.object_id
  end

  def test_multiget
    mget1 = create_dummy_object
    mget2 = create_dummy_object

    test_objects = TestHarnessObject.find([mget1.id, mget2.id])
    assert_equal test_objects[0].id, mget1.id, "Multiget object one is incorrect"
    assert_equal test_objects[1].id, mget2.id, "Multiget object two is incorrect"
  end

  def test_multiget_nil
    mget1 = create_dummy_object
    mget2 = create_dummy_object

    test_objects = TestHarnessObject.find([mget1.id, "ffffffffffffffff", mget2.id])
    assert_equal test_objects[0].id, mget1.id, "Multiget with invalid object object one is incorrect"
    assert_equal test_objects[1].id, mget2.id, "Multiget with invalid object object two is incorrect"
  end

  def test_find_with_exception
    assert_raises ActiveRest::Errors::NotFoundError, "Find! did not raise exception" do
      TestHarnessObject.find!("ffffffffffffffff")
    end
  end

  def test_find_without_exception
    assert_equal TestHarnessObject.find("ffffffffffffffff"), nil, "Find for nil was not nil"
  end

  def test_destroy
    t = create_dummy_object
    t_id = t.id
    t.destroy

    gone = TestHarnessObject.find(t_id)

    assert_nil gone, "Destruction failed"
  end

  def test_finder_id_validation
    record_one = create_dummy_object
    record_two = create_dummy_object

    # valid id
    assert_equal record_one.db_id, TestHarnessObject.find(record_one.id).db_id
    assert_equal record_one.db_id, TestHarnessObject.find!(record_one.id).db_id
    assert_equal record_one.db_id, TestHarnessObject.find!(record_one.db_id).db_id

    # valid array of 1 id
    assert_equal [record_one.db_id], TestHarnessObject.find([record_one.id]).map(&:db_id)
    assert_equal [record_one.db_id], TestHarnessObject.find!([record_one.id]).map(&:db_id)

    # valid array of 2 diff. ids
    assert_equal [record_two.db_id, record_one.db_id], TestHarnessObject.find([record_two.id, record_one.id]).map(&:db_id)
    assert_equal [record_one.db_id, record_two.db_id], TestHarnessObject.find!([record_one.id, record_two.id]).map(&:db_id)

    # valid string id (with hyphen appended string)
    string_appended_id = "#{record_one.id}-hello-there"
    assert_equal record_one.db_id, TestHarnessObject.find(string_appended_id).db_id
    assert_equal record_one.db_id, TestHarnessObject.find!(string_appended_id).db_id

    # invalid ids
    invalid_ids = [
      nil,
      '',
      ' ',
      "@somethingelse:#{record_one.id}",
      "a string",
      10.5,
      record_one.id[0, record_one.id.length - 2], # too short
      record_two.id + "a", # too long
      [record_one.id, "not_valid"], # array with 1 invalid id
      ["wrong", 15.10, :foo] # array all wrong
    ]
    invalid_ids.each do |id|
      assert_raises ActiveRest::Errors::InvalidFindableIDError do
        TestHarnessObject.find(id)
      end

      assert_raises ActiveRest::Errors::InvalidFindableIDError do
        TestHarnessObject.find!(id)
      end
    end
  end

  def test_create_with_no_args
    refute_nil TestHarnessObject.create
    refute_nil TestHarnessObject.create!
  end

  def test_activemodel_conversions
    t = create_dummy_object
    assert_equal t.id.to_s, t.to_param, "Paramaterization via ActiveModel failed"
  end
end
