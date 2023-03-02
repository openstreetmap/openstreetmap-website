require "test_helper"

class ResourceBackendTest < ActiveSupport::TestCase
  def test_valid_url
    klass = OsmCommunityIndex::ResourceBackend

    assert klass.valid_url?(nil)
    assert klass.valid_url?("http://example.com")
    assert klass.valid_url?("mailto:bob@example.com?subject=Foo%20Bar")
    assert klass.valid_url?("xmpp:osm@jabber.example.org?join")

    assert_not klass.valid_url?("javascript:doSomething()")
    assert_not klass.valid_url?("foo:[]")
  end
end
