require 'test_helper'

class NamespaceTest < MiniTest::Unit::TestCase
  def test_namespaced_model
    # root
    assert_equal 'parent_model', ParentModel.entity_name
    parent = ParentModel.create!(:foo => '123')
    assert_equal parent, ParentModel.find!(parent.id)
    assert_equal [parent], ParentModel.find_with_index('foo', parent.foo).to_a

    # inherited from root, 1 deep
    assert_equal 'parent_model-parent_model_subclass', ParentModel::ParentModelSubclass.entity_name
    assert_respond_to ParentModel.new, :foo, "Superclass method undefined"
    assert_respond_to ParentModel::ParentModelSubclass.new, :foo, "Superclass method undefined on subclass"
    assert_respond_to ParentModel::ParentModelSubclass.new, :bar_bar, "Subclass method undefined on subclass"
    refute_respond_to ParentModel.new, :bar_bar, "Subclass method defined on superclass"

    # simple, 1 deep
    assert_equal 'parent_model-namespaced_model', ParentModel::NamespacedModel.entity_name
    record_1 = ParentModel::NamespacedModel.create!(:bar => 'abc', :parent_model => parent)
    assert_equal record_1, ParentModel::NamespacedModel.find!(record_1.id)
    assert_equal [record_1], ParentModel::NamespacedModel.find_with_index('bar', record_1.bar).to_a
    assert_equal parent, ParentModel::NamespacedModel.find!(record_1.id).parent_model
    assert_equal [record_1], ParentModel.find!(parent.id).namespaced_models.to_a

    # simple, 2 deep
    assert_equal 'parent_model-namespaced_model-deep_namespaced_model', ParentModel::NamespacedModel::DeepNamespacedModel.entity_name
    record_2 = ParentModel::NamespacedModel::DeepNamespacedModel.create!(:gyp => 'qqq', :namespaced_model => record_1)
    assert_equal record_2, ParentModel::NamespacedModel::DeepNamespacedModel.find!(record_2.id)
    assert_equal [record_2], ParentModel::NamespacedModel::DeepNamespacedModel.find_with_index('gyp', record_2.gyp).to_a
    assert_equal record_1, ParentModel::NamespacedModel::DeepNamespacedModel.find!(record_2.id).namespaced_model
    parent.update_attributes!(:deep_namespaced_model => record_2)
    assert_equal record_2, ParentModel.find!(parent.id).deep_namespaced_model
    assert_equal [parent], ParentModel::NamespacedModel::DeepNamespacedModel.find!(record_2.id).parent_models.to_a

    # inherited, 1 deep
    assert_equal 'parent_model-namespaced_subclassed_model', ParentModel::NamespacedSubclassedModel.entity_name
    record = ParentModel::NamespacedSubclassedModel.create!(:sum => '555', :test_superclass_method => 'hi')
    assert_equal record, ParentModel::NamespacedSubclassedModel.find!(record.id)
    assert_equal 'hi', record.test_superclass_method
    assert_equal 'hi', ParentModel::NamespacedSubclassedModel.find!(record.id).test_superclass_method
  end

  def test_namespaced_polymorphic_has_one
    child = ParentModel::NamespacedModel::DeepNamespacedModel.create!(:gyp => 'qqq')
    parent = ParentModel.create!(:foo => '123', :namespaced_polymorphic_has_one => child)
    assert_equal child, parent.namespaced_polymorphic_has_one
    parent = ParentModel.find!(parent.id)
    assert_equal child, parent.namespaced_polymorphic_has_one

    child = OtherParentModel::OtherNamespacedModel.create!
    parent = ParentModel.create!(:foo => '123', :namespaced_polymorphic_has_one => child)
    assert_equal child, parent.namespaced_polymorphic_has_one
    parent = ParentModel.find!(parent.id)
    assert_equal child, parent.namespaced_polymorphic_has_one
  end
end
