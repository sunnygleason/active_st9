require 'test_helper'

class CallbackTest < MiniTest::Unit::TestCase
  def test_callbacks
    t = TestCallbacksObject.new
    t.save
    assert_equal t.instance_variable_get("@before_saved"), true, "Before saved callback not triggered"
    assert_equal t.instance_variable_get("@after_saved"), true, "After saved callback not triggered"
  end

  def test_find_callback
    record = TestFindCallback.create(:test_string => "foo")
    assert_equal "foo", record.test_string

    record = TestFindCallback.find(record.id)
    assert_equal "ohai_from_after_find", record.test_string
  end

  def test_initialize_callback
    record = TestInitializeCallback.new(:test_string => "foo")
    assert_equal "ohai_from_after_initialize", record.test_string

    record.test_string = "foo"
    record.save!
    assert_equal "foo", record.test_string

    record = TestInitializeCallback.find(record.id)
    assert_equal "ohai_from_after_initialize", record.test_string
  end
end
