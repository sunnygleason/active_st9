require 'test_helper'

class TimestampTest < MiniTest::Unit::TestCase
  def test_bonus_timestamps
    b = BonusTimestamps.new
    b.bonus_timestamp = Time.at(1)
    b.save
    b2 = BonusTimestamps.find(b.id)
    assert_instance_of Time, b2.bonus_timestamp
    assert_equal 1, b2.bonus_timestamp.to_i
  end

  def test_timestamps
    h = HasTimestamps.new
    c_a = h.created_at
    u_a = h.updated_at
    h.save
    refute_equal c_a, h.created_at
    c_a = h.created_at
    refute_equal u_a, h.updated_at
    u_a = h.updated_at
    h = HasTimestamps.find(h.id)
    assert_instance_of Time, h.created_at
    assert_instance_of Time, h.updated_at
    h.blah = "test"
    h.save
    assert_equal c_a.to_i, h.created_at.utc.to_i
  end
end
