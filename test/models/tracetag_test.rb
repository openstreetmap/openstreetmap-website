require "test_helper"

class TracetagTest < ActiveSupport::TestCase
  def test_validations
    tracetag_valid({})
    tracetag_valid({ :tag => nil }, false)
    tracetag_valid({ :tag => "" }, false)
    tracetag_valid(:tag => "a")
    tracetag_valid(:tag => "a" * 255)
    tracetag_valid({ :tag => "a" * 256 }, false)
    tracetag_valid({ :tag => "a/b" }, false)
    tracetag_valid({ :tag => "a;b" }, false)
    tracetag_valid({ :tag => "a.b" }, false)
    tracetag_valid({ :tag => "a,b" }, false)
    tracetag_valid({ :tag => "a?b" }, false)
  end

  private

  def tracetag_valid(attrs, result = true)
    entry = build(:tracetag)
    entry.assign_attributes(attrs)
    assert_equal result, entry.valid?, "Expected #{attrs.inspect} to be #{result}"
  end
end
