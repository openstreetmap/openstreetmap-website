require "test_helper"

class ChangesetHelperTest < ActionView::TestCase
  def test_changeset_user_link
    changeset = create(:changeset)
    assert_equal %(<a href="/user/#{ERB::Util.u(changeset.user.display_name)}">#{changeset.user.display_name}</a>), changeset_user_link(changeset)

    changeset = create(:changeset, :user => create(:user, :data_public => false))
    assert_equal "anonymous", changeset_user_link(changeset)

    changeset = create(:changeset, :user => create(:user, :deleted))
    assert_equal "deleted", changeset_user_link(changeset)
  end

  def test_changeset_details
    changeset = create(:changeset, :created_at => Time.utc(2007, 1, 1, 0, 0, 0), :user => create(:user, :data_public => false))
    # We need to explicitly reset the closed_at to some point in the future, and avoid the before_save callback
    changeset.update_column(:closed_at, Time.now.utc + 1.day) # rubocop:disable Rails/SkipsModelValidations

    assert_match %r{^Created <abbr title='Mon, 01 Jan 2007 00:00:00 \+0000'>.*</abbr> by anonymous$}, changeset_details(changeset)

    changeset = create(:changeset, :created_at => Time.utc(2007, 1, 1, 0, 0, 0), :closed_at => Time.utc(2007, 1, 2, 0, 0, 0))
    user_link = %(<a href="/user/#{ERB::Util.u(changeset.user.display_name)}">#{changeset.user.display_name}</a>)

    assert_match %r{^Closed <abbr title='Created: Mon, 01 Jan 2007 00:00:00 \+0000&#10;Closed: Tue, 02 Jan 2007 00:00:00 \+0000'>.*</abbr> by #{user_link}$}, changeset_details(changeset)
  end
end
