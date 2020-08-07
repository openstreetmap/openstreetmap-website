require "test_helper"

class MicrocosmMemberTest < ActiveSupport::TestCase
  def test_microcosm_validations
    validate({}, true)

    validate({ :microcosm_id => nil }, false)
    validate({ :microcosm_id => "" }, false)

    validate({ :user_id => nil }, false)
    validate({ :user_id => "" }, false)

    validate({ :role => "overlord" }, false)
  end
end
