require 'test_helper'

class FulltextTest < MiniTest::Unit::TestCase
  def test_simple_fulltext_schema
    s = SimpleFulltextHost.to_schema
    assert_equal s['fulltexts'], [{"name"=>"fulltext", "parentType"=>nil, "parentIdentifierAttribute"=>nil, "cols"=>[{"name"=>:foo}, {"name"=>:bar}]}]
  end

  def test_simple_fulltext
    m = SimpleFulltextHost.new
    m.foo = "dude"
    m.bar = "where's my car"
    m.save
  end
  
  def test_complex_fulltext_schema
    s = ComplexFulltextHost.to_schema
    assert_equal s['fulltexts'], [{"name"=>"fulltext", "parentType"=>"SimpleFulltextHost", "parentIdentifierAttribute"=>"parent", "cols"=>[{"name"=>:uno}, {"name"=>:dos}]}]
  end

  def test_complex_fulltext
    p = SimpleFulltextHost.new
    p.foo = "dude"
    p.bar = "where's my car"
    p.save

    m = ComplexFulltextHost.new
    m.uno = "amigo"
    m.dos = "donde esta mi coche"
    m.parent = p
    m.save
  end
end
