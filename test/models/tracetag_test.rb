require "test_helper"

class TracetagTest < ActiveSupport::TestCase
  def test_validations
    tracetag_valid({})
    tracetag_valid({ :tag => nil }, :valid => false)
    tracetag_valid({ :tag => "" }, :valid => false)
    tracetag_valid({ :tag => "a" })
    tracetag_valid({ :tag => "a" * 255 })
    tracetag_valid({ :tag => "a" * 256 }, :valid => false)
    tracetag_valid({ :tag => "a/b" }, :valid => false)
    tracetag_valid({ :tag => "a;b" }, :valid => false)
    tracetag_valid({ :tag => "a.b" }, :valid => false)
    tracetag_valid({ :tag => "a,b" }, :valid => false)
    tracetag_valid({ :tag => "a?b" }, :valid => false)
  end

  private

  def tracetag_valid(attrs, valid: true)
    entry = build(:tracetag)
    entry.assign_attributes(attrs)
    assert_equal valid, entry.valid?, "Expected #{attrs.inspect} to be #{valid}"
  end
end
