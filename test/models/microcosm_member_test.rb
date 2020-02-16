require "test_helper"

class MicrocosmMemberTest < ActiveSupport::TestCase
  def test_microcosm_validations
    validate({})

    validate({ :microcosm_id => nil }, false)
    validate({ :microcosm_id => "" }, false)

    validate({ :user_id => nil }, false)
    validate({ :user_id => "" }, false)

    validate({ :role => "overlord" }, false)
  end

  # There's a possibility to factory this out.  See microcosm_test.rb.
  def validate(attrs, result = true)
    object = build(:microcosm_member, attrs)
    valid = object.valid?
    errors = object.errors.messages
    assert_equal result, object.valid?, "Expected #{attrs.inspect} to be #{result} but #{errors}"
  end
end
