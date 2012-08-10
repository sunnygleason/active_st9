require 'test_helper'

class SubclassTest < MiniTest::Unit::TestCase
  def test_subclassing
    s = TestSubclass.new
    su = TestSuperclass.new

    assert_respond_to su, :test_superclass_method, "Superclass method undefined"
    assert_respond_to s, :test_superclass_method, "Superclass method undefined on subclass"
    assert_respond_to s, :test_subclass_method, "Subclass method undefined on subclass"
    refute_respond_to su, :test_subclass_method, "Subclass method defined on superclass"

    assert_equal 'test_superclass', TestSuperclass.entity_name
    assert_equal 'test_subclass', TestSubclass.entity_name
  end
end
