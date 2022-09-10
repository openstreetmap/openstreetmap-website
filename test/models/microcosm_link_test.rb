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
end
