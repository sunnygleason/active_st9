require "bundler/setup"
require "active_rest"
require "minitest/autorun"
require "minitest/unit"
require "active_model/lint"

## ST9 Config

CONFIG = {
  "host" => "localhost",
  "port" => "7331",
  'allow_cascades' => true
}
ActiveRest::Config.config = CONFIG
ActiveRest::Config::LOGGER = ::Logger.new(STDOUT)
ActiveRest::Config::LOGGER.level = Logger::INFO

## Models

class TestHarnessObject < ActiveRest::Base
  utf8_smallstring :test_data_one
end

class TestHarnessProxyObject < ActiveSupport::BasicObject
  def initialize(target)
    @proxy_target = target
  end

private

  def method_missing(name, *args, &blk)
    @proxy_target.send(name, *args, &blk)
  end
end

class TestValidatorsObject < ActiveRest::Base
  utf8_smallstring :count # This is a string because we are checking to see if the validator can determine the numericality of a non-i32 field
  validates :count, :numericality => true
end

class TestCallbacksObject < ActiveRest::Base
  before_save :bef_save
  after_save :af_save

  def bef_save
    @before_saved = true
  end

  def af_save
    @after_saved = true
  end
end

class RelationTarget < ActiveRest::Base
  has_one :parent, :kind => "RelationHost"
end

class RelationHost < ActiveRest::Base
  has_one :relation_target
  has_one :relation_target_two, :kind => :relation_target
  has_one :parent, :kind => "HasManyThroughHost"
end

class StaticAttributesHost < ActiveRest::Base
  i32 :test_int
  utf8_smallstring :test_string
  boolean :awesome
end

class IndexHost < ActiveRest::Base
  i32 :test_int
  index "IntIndex", [:test_int], :sort => :desc
end

class ComplexIndexHost < ActiveRest::Base
  i32 :test_int
  index "test_int", [:test_int], :sort => :desc
end

class MultiIndexHost < ActiveRest::Base
  i32 :test_int_one
  i32 :test_int_two
  index "test_ints", [:test_int_one, :test_int_two], :sort => :desc
end

class UniqueStringIndexHost < ActiveRest::Base
  utf8_smallstring :test_uniq_string, :nullable => false
  index "uniq", [:test_uniq_string], :sort => :desc, :unique => true
end

class UniqueStringTransformIndexHost < ActiveRest::Base
  utf8_smallstring :test_uniq_string, :nullable => false
  index "uniq", [:test_uniq_string], :sort => :desc, :unique => true, :transform => :LOWERCASE
end

class UniqueIntIndexHost < ActiveRest::Base
  i32 :test_uniq_int, :nullable => false
  index "uniq", [:test_uniq_int], :sort => :desc, :unique => true
end

class UniqueCompositeIndexHost < ActiveRest::Base
  utf8_smallstring :test_uniq_string, :nullable => false
  i32 :test_uniq_int, :nullable => false
  index "uniq", [:test_uniq_string, :test_uniq_int], :sort => :desc, :unique => true
end

class SimpleBooleanCountHost < ActiveRest::Base
  boolean :is_cool, :nullable => false
  counter "by_cool", [:is_cool], :sort => :desc
end

class CompositeCountHost < ActiveRest::Base
  utf8_smallstring :attr1, :nullable => false
  boolean :attr2, :nullable => false
  enum :attr3, ["ONE", "TWO", "THREE"], :nullable => false

  counter "by_attr1", [:attr1], :sort => :desc
  counter "by_attr2", [:attr2], :sort => :desc
  counter "by_attr3", [:attr3], :sort => :desc
  counter "by_all_attrs", [:attr1, :attr2, :attr3], :sort => :desc
end

class HasManyTargetTargetTarget < ActiveRest::Base
  has_one :parent, :kind => "HasManyTargetTarget"
end

class HasManyTargetTarget < ActiveRest::Base
  has_one :parent, :kind => "HasManyTarget"
  has_many :targets, :foreign_key => "parent_id", :kind => "HasManyTargetTargetTarget"
end

class HasManyTarget < ActiveRest::Base
  has_one :parent, :kind => "HasManyHost"
  has_many :targets, :foreign_key => "parent_id", :kind => "HasManyTargetTarget"
end

class HasManyDependentDestroyTargetTarget < ActiveRest::Base
  has_one :parent, :kind => "HasManyDependentDestroyTarget"

  @@after_destroy_called = 0

  def self.after_destroy_called
    @@after_destroy_called
  end

  after_destroy do
    @@after_destroy_called += 1
  end
end

class HasManyDependentDestroyTarget < ActiveRest::Base
  has_one :parent, :kind => "HasManyDependentDestroyHost"
  has_many :targets, {:foreign_key => "parent_id", :kind => "HasManyDependentDestroyTargetTarget", :dependent => :destroy}
end

class HasManyHost < ActiveRest::Base
  has_many :targets, {:foreign_key => "parent_id", :kind => "HasManyTarget"}
end

class HasManyDependentDestroyHost < ActiveRest::Base
  has_many :targets, {:foreign_key => "parent_id", :kind => "HasManyDependentDestroyTarget"}
end

class HasOneHost < ActiveRest::Base
  has_one :child, :kind => 'HasOneChild'
end

class HasOneChild < ActiveRest::Base
  utf8_smallstring :foo
end

class QuarantinedHasManyTarget < ActiveRest::Base
  include ActiveRest::Quarantinable
  has_one :parent, :kind => "QuarantinedHasManyHost"
end

class NonQuarantinedHasManyTarget < ActiveRest::Base
  has_one :parent, :kind => "QuarantinedHasManyHost"
end

class QuarantinedHasManyHost < ActiveRest::Base
  include ActiveRest::Quarantinable
  has_many :quarantinable_targets, {:foreign_key => "parent_id", :kind => "QuarantinedHasManyTarget"}
  has_many :targets, {:foreign_key => "parent_id", :kind => "NonQuarantinedHasManyTarget"}
end

class HasManyThroughHost < ActiveRest::Base
  has_many :relation_targets, :through => :RelationHost, :foreign_key => "parent_id"
  has_many :relation_hosts, :foreign_key => "parent_id", :kind => "RelationHost"
end

class HasTimestamps < ActiveRest::Base
  include ActiveRest::Timestamps
  utf8_smallstring :blah # Dummy field to update
end

class BonusTimestamps < ActiveRest::Base
  utc_date_secs :bonus_timestamp
end

class IndexedTimestamps < ActiveRest::Base
  utc_date_secs :bonus_timestamp
  index "time_index", [:bonus_timestamp], :sort => :desc
end

class CompoundIndexedTimestamps < ActiveRest::Base
  utc_date_secs :timestamp
  i32 :int
  index "compound_index", [:timestamp, :int], :sort => :desc
end

class TestSuperclass < ActiveRest::Base
  utf8_smallstring :test_superclass_method
  i32 :number
  index 'number', [:number], :sort => :desc
end

# NOTE indexes/counters defined on subclasses do not work with inherited types in ActiveRest
class TestSubclass < TestSuperclass
  utf8_smallstring :test_subclass_method
end

class EnumHost < ActiveRest::Base
  enum :test_enum, ["TESTONE", "TESTTWO", "TESTTHREE"]
end

class OrmAdapterIndexHost < ActiveRest::Base
  utf8_smallstring :string_one
  utf8_smallstring :string_two
  index "string_one", [:string_one], :sort => :desc
  index "string_two", [:string_two], :sort => :desc
end

class TestInitializeCallback < ActiveRest::Base
  utf8_smallstring :test_string
  after_initialize do |record|
    record.test_string = "ohai_from_after_initialize"
  end
end

class TestFindCallback < ActiveRest::Base
  utf8_smallstring :test_string
  after_find do |record|
    record.test_string = "ohai_from_after_find"
  end
end

class SerializedAttributes < ActiveRest::Base
  utf8_smallstring :dataz, :serialized => true
end

class SimpleInHost < ActiveRest::Base
  i32 :int
  index "idx", [:int], :sort => :desc
end

class MultiInHost < ActiveRest::Base
  i32 :int
  utf8_smallstring :sm_string
  index "idx", [:int, :sm_string], :sort => :desc
end

class EnumInHost < ActiveRest::Base
  enum :number, %w[one two three four five]
  index "idx", [:number], :sort => :desc
end

class SubclassSerializedAttributes < SerializedAttributes
end

class StringHost < ActiveRest::Base
  utf8_smallstring :str
  index 'str_idx', [:str], :sort => :asc
end

class ImageMedia < ActiveRest::Base
  def media_type
    'image'
  end
end

class VideoMedia < ActiveRest::Base
  def media_type
    'video'
  end
end

class PolymorphicHost < ActiveRest::Base
  has_one :media, :polymorphic => true
end

class InstanceMethodHost < ActiveRest::Base
  i32 :int
  index 'int', [:int], :sort => :asc
end

class DirtyHost < ActiveRest::Base
  utf8_smallstring :title
  utf8_smallstring :description
  utc_date_secs :begins_at
end

class AliasAttributeClassHelperHost < ActiveRest::Base
  utf8_smallstring :foo
  alias_attribute :bar, :foo
end

class SimpleFulltextHost < ActiveRest::Base
  utf8_smallstring :foo
  utf8_text :bar
  i32 :baz
  fulltext [:foo, :bar]
end

class ComplexFulltextHost < ActiveRest::Base
  utf8_smallstring :uno
  utf8_text :dos
  i32 :tres
  has_one :parent, :kind => 'SimpleFulltextHost'

  fulltext [:uno, :dos], :parent_type => "SimpleFulltextHost", :parent_identifier_attribute => "parent"
end

class ParentModel < ActiveRest::Base
  class NamespacedModel < ActiveRest::Base
    class DeepNamespacedModel < ActiveRest::Base
      utf8_smallstring :gyp
      index 'gyp', [:gyp], :sort => :desc
      has_one :namespaced_model, :kind => 'ParentModel::NamespacedModel'
      has_many :parent_models, :kind => ::ParentModel
    end

    utf8_smallstring :bar
    index 'bar', [:bar], :sort => :desc
    has_one :parent_model
    has_many :deep_namespaced_models, :kind => ParentModel::NamespacedModel::DeepNamespacedModel
  end

  utf8_smallstring :foo
  index 'foo', [:foo], :sort => :desc
  has_many :namespaced_models, :kind => 'ParentModel::NamespacedModel'
  has_one :deep_namespaced_model, :kind => ParentModel::NamespacedModel::DeepNamespacedModel
  has_one :namespaced_polymorphic_has_one, :polymorphic => true

  class ParentModelSubclass < ::ParentModel
    utf8_smallstring :bar_bar
  end

  # NOTE this is pretty whacky (i.e. do not do it) but it works
  class NamespacedSubclassedModel < ::TestSuperclass
    utf8_smallstring :sum
    index 'sum', [:sum], :sort => :desc
  end
end

class OtherParentModel < ActiveRest::Base
  class OtherNamespacedModel < ActiveRest::Base
  end
end

class QuarantinedModel < ActiveRest::Base
  include ActiveRest::Quarantinable
  utf8_smallstring :name
  index 'name', [:name], :sort => :desc
end

class TestIndexAllObject < ActiveRest::Base
  utf8_smallstring :not_really_important
end

class TestUniquenessObject < ActiveRest::Base
  utf8_smallstring :name, :nullable => false
  index 'name', [:name], :sort => :asc, :unique => true
  validates_uniqueness_of :name
end

class TestUniquenessWithIndexNameObject < ActiveRest::Base
  utf8_smallstring :name, :nullable => false
  index 'uniq', [:name], :sort => :asc, :unique => true
  validates_uniqueness_of :name, :index => 'uniq'
end

class OverriddenAttributesChild < ActiveRest::Base
  has_one :overridden_attributes_host
end

class OverriddenAttributesHost < ActiveRest::Base
  utf8_smallstring :test_string
  boolean :wise
  has_one :child, :kind => 'OverriddenAttributesChild'
  has_many :relations, :kind => 'OverriddenAttributesChild'

  def wise=(v)
    super !v
  end

  def child
    super || OverriddenAttributesChild.new(:overridden_attributes_host => self)
  end

  def relations(*args)
    [123] + super.to_a
  end
end

class TestAttrObject < ActiveRest::Base
  attr_accessor :thing1

  utf8_smallstring :thing2, :nullable => false

  validates :thing2, :presence => true
end

class SubclassedOverriddenAttributesHost < OverriddenAttributesHost
  def test_string
    super + "_COOL"
  end
end

## Setup Schema

ActiveRest::Utility.nuke!(false)
ObjectSpace.each_object(Class).select { |k| k < ActiveRest::Base }.each(&:post_schema)

## Common

class MiniTest::Unit::TestCase
  def setup
    ActiveRest::Utility.nuke!(true)
  end

  private

  def create_dummy_object
    TestHarnessObject.create(:test_data_one => "test data one")
  end
end
