require "test_helper"

class CommunityLinkTest < ActiveSupport::TestCase
  def test_community_link_validations
    validate({}, true)

    validate({ :community_id => nil }, false)
    validate({ :community_id => "" }, false)

    validate({ :text => nil }, false)
    validate({ :text => "" }, false)

    validate({ :url => nil }, false)
    validate({ :url => "" }, false)

    validate({ :url => "foo" }, false)
    scheme = "https://"
    validate({ :url => scheme + ("a" * (255 - scheme.length)) }, true)
    validate({ :url => scheme + ("a" * (256 - scheme.length)) }, false)
  end
end
