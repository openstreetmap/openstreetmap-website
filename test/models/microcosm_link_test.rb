require "test_helper"

class MicrocosmLinkTest < ActiveSupport::TestCase
  def test_microcosm_link_validations
    validate({}, true)

    validate({ :microcosm_id => nil }, false)
    validate({ :microcosm_id => "" }, false)

    validate({ :site => nil }, false)
    validate({ :site => "" }, false)

    validate({ :url => nil }, false)
    validate({ :url => "" }, false)

    validate({ :url => "foo" }, false)
    scheme = "https://"
    validate({ :url => scheme + ("a" * (255 - scheme.length)) }, true)
    validate({ :url => scheme + ("a" * (256 - scheme.length)) }, false)
  end

  # There's a possibility to factory this out.  See microcosm_test.rb.
  def validate(attrs, result)
    object = build(:microcosm_link, attrs)
    valid = object.valid?
    errors = object.errors.messages
    assert_equal result, valid, "Expected #{attrs.inspect} to be #{result} but #{errors}"
  end
end
