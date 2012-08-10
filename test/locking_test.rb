require 'test_helper'

class LockingTest < MiniTest::Unit::TestCase
  def test_optimistic_versioning_happy
    t = create_dummy_object
    assert_equal t.version, "1", "version attribute not created"

    t.test_data_one = "test data two"
    t.save

    assert_equal t.test_data_one, TestHarnessObject.find(t.id).test_data_one, "Saved object's attributes were not saved"
    assert_equal t.version, "2", "version attribute not updated"

    t.test_data_one = "test data three"
    t.save

    assert_equal t.test_data_one, TestHarnessObject.find(t.id).test_data_one, "Saved object's attributes were not updated"
    assert_equal t.version, "3", "version attribute not updated"
  end

  def test_optimistic_versioning_sad
    t = create_dummy_object
    assert_equal t.version, "1", "version attribute not created"

    t.send("version=", nil)
    assert_raises ActiveRest::Errors::InvalidClientRequestError, "Save with missing version did not raise exception" do
      t.save!
    end

    t.send("version=", "0")
    assert_raises ActiveRest::Errors::ObsoleteVersionError, "Save with obsolete version did not raise exception" do
      t.save!
    end

    t.send("version=", "1")
    t.test_data_one = "test data two"
    t.save

    assert_equal t.test_data_one, TestHarnessObject.find(t.id).test_data_one, "Saved object's attributes were not saved"
    assert_equal t.version, "2", "version attribute not updated"
  end
end
