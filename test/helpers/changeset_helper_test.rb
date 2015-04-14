require "test_helper"

class ChangesetHelperTest < ActionView::TestCase
  fixtures :changesets, :users

  def test_changeset_user_link
    assert_equal "<a href=\"/user/test2\">test2</a>", changeset_user_link(changesets(:public_user_first_change))
    assert_equal "anonymous", changeset_user_link(changesets(:normal_user_first_change))
  end

  def test_changeset_details
    assert_match %r{^Created <abbr title='Mon, 01 Jan 2007 00:00:00 \+0000'>.*</abbr> by anonymous$}, changeset_details(changesets(:normal_user_first_change))
    assert_match %r{^Closed <abbr title='Created: Mon, 01 Jan 2007 00:00:00 \+0000&#10;Closed: Tue, 02 Jan 2007 00:00:00 \+0000'>.*</abbr> by <a href="/user/test2">test2</a>$}, changeset_details(changesets(:public_user_closed_change))
  end
end
