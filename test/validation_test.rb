require 'test_helper'

class ValidationTest < MiniTest::Unit::TestCase
  def test_validators
    t = TestValidatorsObject.new
    t.count = 2
    t.save
    assert_equal "2", TestValidatorsObject.find(t.id).count, "Validated object did not save"
  end

  def test_validators_fail
    t = TestValidatorsObject.new
    t.count = "TEST"
    assert_raises ActiveRest::Errors::ValidationError, "Non-numeric value did not raise validation exception" do
      t.save!
    end
  end

  def test_uniqueness_validator
    existing = TestUniquenessObject.create(:name => 'name')

    assert existing.valid?, "record should be valid if it is the only one with its value"


    unique = TestUniquenessObject.new(:name => 'other_name')
    assert unique.valid?

    non_unique = TestUniquenessObject.new(:name => 'name')
    refute non_unique.valid?, "uniqueness validation failed"
  end

  def test_uniqueness_validator_with_index_name
    existing = TestUniquenessWithIndexNameObject.create(:name => 'name')

    unique = TestUniquenessWithIndexNameObject.new(:name => 'other_name')
    assert unique.valid?

    non_unique = TestUniquenessWithIndexNameObject.new(:name => 'name')
    refute non_unique.valid?, "uniqueness validation failed"
  end
end

