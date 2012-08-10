require 'test_helper'

class AttributeTest < MiniTest::Unit::TestCase
  def test_boolean_question_mark_getter
    record = StaticAttributesHost.new

    assert_nil record.awesome
    assert !record.awesome?

    record.awesome = true
    assert record.awesome?

    record.awesome = false
    assert !record.awesome?
  end

  def test_setting_boolean_attribute
    record = StaticAttributesHost.new

    examples = {
      nil => nil,
      true => true,
      false => false,
      "true" => true,
      "false" => false,
      "0" => false,
      "1" => true,
      0 => false,
      1 => true,
      3.142 => false,
      Object.new => false,
      [1,2,3] => false,
      { :my => 'shoe' } => false
    }

    examples.each do |input, expected_output|
      record.awesome = input

      assert_equal expected_output, record.awesome, "did not map #{input.inspect} --> #{expected_output.inspect}"
      assert_equal !!expected_output, record.awesome?, "did not map #{input.inspect} --> #{!!expected_output.inspect}"
    end
  end

  def test_setting_time_various_ways
    s = "2011-06-01T07:00:00.000Z"
    t = Time.parse(s)

    # time
    record = BonusTimestamps.new(:bonus_timestamp => t)
    assert_equal t, record.bonus_timestamp

    # iso8601 string
    record = BonusTimestamps.new(:bonus_timestamp => s)
    assert_equal t, record.bonus_timestamp

    # time since epoch as string
    record.bonus_timestamp = t.to_i.to_s
    assert_equal t, record.bonus_timestamp

    # time since epoch as integer
    record.bonus_timestamp = t.to_i
    assert_equal t, record.bonus_timestamp

    # empty string
    record.bonus_timestamp = ""
    assert_equal nil, record.bonus_timestamp
  end

  def test_serialized_attributes
    allowable_values = [
      [{"type" => "get", "content" => "foo bar"}],
      { "foo" => "bar" },
      [1, 2, 3],
      []
    ]

    [SerializedAttributes, SubclassSerializedAttributes].each do |klass|
      allowable_values.each do |val|
        record = klass.new(:dataz => val)
        assert_equal val, record.dataz

        record.dataz = val
        assert_equal val, record.dataz
        record.save!
        blah = klass.find(record.id)
        assert_equal val, klass.find(record.id).dataz

        record.dataz = nil
        assert_equal nil, record.dataz

        record.dataz_raw = nil
        assert_equal nil, record.dataz
      end

      non_allowable_values = [
        1,
        3.142,
        ""
      ]

      non_allowable_values.each do |val|
        assert_raises ActiveRest::Errors::ValidationError, "Only allowed arrays or hashes for serialized attributes" do
            record = klass.new(:dataz => val)
        end
      end
    end
  end

  def test_time_zone_support
    current_time_zone = Time.zone

    begin
      Time.zone = "Pacific Time (US & Canada)" # UTC -08:00
      @now = Time.zone.parse("2009-10-11 12:13:14") # ensures 0 usecs

      # read/write in local timezone
      record = BonusTimestamps.new(:bonus_timestamp => @now)
      assert_equal @now, record.bonus_timestamp
      assert_equal Time.zone, record.bonus_timestamp.time_zone

      # read when moved into another timezone
      Time.zone = "Beijing" # UTC +08:00
      assert_equal @now, record.bonus_timestamp
      assert_equal Time.zone, record.bonus_timestamp.time_zone

      # read/write when moved into another timezone
      Time.zone = "Paris" # UTC +01:00
      record.bonus_timestamp = @now.in_time_zone
      assert_equal @now, record.bonus_timestamp
      assert_equal Time.zone, record.bonus_timestamp.time_zone

      # read/write in utc
      record = BonusTimestamps.new(:bonus_timestamp => @now.utc)
      assert_equal @now.utc, record.bonus_timestamp
      assert_equal Time.zone, record.bonus_timestamp.time_zone

      # ensure reading of saved record comes back in local time zone
      record.save!
      Time.zone = "Pacific Time (US & Canada)"
      record = BonusTimestamps.find(record.id)
      assert_equal @now, record.bonus_timestamp
      assert_equal Time.zone, record.bonus_timestamp.time_zone
    ensure
      Time.zone = current_time_zone
    end
  end

  def test_setting_i32
    record = StaticAttributesHost.new(:test_int => 10)
    assert_equal 10, record.test_int

    record.test_int = nil
    assert_equal nil, record.test_int

    record.test_int = "5"
    assert_equal 5, record.test_int

    record.save!
    assert_equal 5, StaticAttributesHost.find(record.id).test_int
  end

  def test_changed_attributes
    t = create_dummy_object
    t.test_data_one = "test data two"
    assert t.changed_attributes.include?("test_data_one")
    assert t.test_data_one_changed?

    d = DirtyHost.create!(:title => 'Title of Record')
    assert_equal 1, d.previous_changes.size
    assert_equal 0, d.changed_attributes.size

    dl = DirtyHost.find!(d.id)
    assert_equal nil, dl.previous_changes
    assert_equal 0, dl.changed_attributes.size

    dl.description = 'Que voy hacer je suis perdu'
    assert dl.changed?
    assert_equal 1, dl.changed_attributes.size
    assert_equal [nil, 'Que voy hacer je suis perdu'], dl.description_change
    assert_equal nil, dl.description_was

    dl.save
    assert_equal 1, dl.previous_changes.size
    assert_equal 0, dl.changed_attributes.size
    refute dl.changed?
    refute dl.description_changed?

    dl.title = 'Alpha'
    dl.title = 'Beta'
    dl.save
    assert dl.previous_changes.keys.one? { |da| da == 'title' }
  end

  def test_static_attributes
    sh = StaticAttributesHost.new
    assert_respond_to sh, :test_int, "Getter functions for static attributes were not created"
    assert_respond_to sh, :test_string, "Getter functions for static attributes were not created"
    sh.test_int = 1
    sh.test_string = "test"
    assert_equal 1, sh.test_int, "Static integer attribute not set"
    assert_equal "test", sh.test_string, "Static string attribute not set"
    sh.save
    sh = StaticAttributesHost.find(sh.id)
    assert_equal 1, sh.test_int, "Static integer attribute not deserialized"
    assert_equal "test", sh.test_string, "Static string attribute not deserialized"
  end

  def test_nil_static_attributes # Nil is a valid value for any type at this point
    sh = StaticAttributesHost.new
    sh.test_int = nil
    sh.save
    sh2 = StaticAttributesHost.find(sh.id)
    assert_equal nil, sh2.test_int, "Integer field did not persist nil"
  end

  def test_alias_attribute_class_helper
    obj = AliasAttributeClassHelperHost.new

    assert_nil obj.foo
    assert_nil obj.bar

    obj.bar = "gyp"
    assert_equal "gyp", obj.foo
    assert_equal "gyp", obj.bar

    obj.foo = "sum"
    assert_equal "sum", obj.foo
    assert_equal "sum", obj.bar
  end

  def test_enum_host
    e = EnumHost.new
    e.test_enum = "TESTONE"
    e.save
    e = EnumHost.find(e.id)

    assert_equal e.test_enum, "TESTONE", "Enum did not save properly"
  end

  def test_instance_methods
    # empty?
    e = InstanceMethodHost.create(:int => 1)

    results = InstanceMethodHost.find_with_index('int', 0)
    assert results.respond_to?(:empty?)
    assert results.empty? == true

    results = InstanceMethodHost.find_with_index('int', 1)
    assert results.empty? == false
  end

  def test_overriding_attributes_with_super
    # override static attribute writer on base class
    record = OverriddenAttributesHost.new(:wise => true)
    refute record.wise
    record.wise = false
    assert record.wise

    # override has_many accessor on base class
    record = OverriddenAttributesHost.new
    assert_equal 123, record.relations.first

    # override has_one accessor on base class
    record = OverriddenAttributesHost.new(:child => nil)
    assert record.child.new_record?

    # override static attribute accessor in subclass
    record = SubclassedOverriddenAttributesHost.new(:test_string => "123")
    assert_equal '123_COOL', record.test_string
  end

  def test_attr_accessor_with_update_attributes_should_save
    record = TestAttrObject.create(:thing2 => 'asdf')
    record.update_attributes(:thing1 => 'asdf', :thing2 => 'fdsa')

    assert_equal 'asdf', record.thing1
    assert_equal nil, record.reloaded.thing1
    assert_equal 'fdsa', record.reloaded.thing2
  end

  def test_attr_accessor_with_update_attributes_should_show_errors
    record = TestAttrObject.create(:thing2 => 'asdf')
    record.update_attributes(:thing1 => 'asdf', :thing2 => nil)

    assert_equal 'asdf', record.thing1
    assert_equal nil, record.reloaded.thing1
    assert_equal 'asdf', record.reloaded.thing2
    assert_equal ["Thing2 can't be blank"], record.errors.full_messages
  end
end
