require 'test_helper'

class ActiveModelTest < MiniTest::Unit::TestCase
  include ActiveModel::Lint::Tests

  private

  # called by ActiveModel::Lint::Test
  def model
    @model ||= create_dummy_object
  end
end
