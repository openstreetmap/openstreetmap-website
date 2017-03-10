require "test_helper"

class NoteHelperTest < ActionView::TestCase
  include ERB::Util
  include ApplicationHelper

  def test_note_event
    date = Time.new(2014, 3, 5, 21, 37, 45, "+00:00")
    user = create(:user)

    assert_match %r{^Created by anonymous <abbr title='Wed, 05 Mar 2014 21:37:45 \+0000'><span title=" 5 March 2014 at 21:37">.*</span> ago</abbr>$}, note_event("open", date, nil)
    assert_match %r{^Resolved by <a href="/user/#{URI.encode(user.display_name)}">#{user.display_name}</a> <abbr title='Wed, 05 Mar 2014 21:37:45 \+0000'><span title=" 5 March 2014 at 21:37">.*</span> ago</abbr>$}, note_event("closed", date, user)
  end

  def test_note_author
    deleted_user = create(:user, :deleted)
    user = create(:user)
    assert_equal "", note_author(nil)
    assert_equal "deleted", note_author(deleted_user)
    assert_equal "<a href=\"/user/#{URI.encode(user.display_name)}\">#{user.display_name}</a>", note_author(user)
    assert_equal "<a href=\"http://test.host/user/#{URI.encode(user.display_name)}\">#{user.display_name}</a>", note_author(user, :only_path => false)
  end
end
