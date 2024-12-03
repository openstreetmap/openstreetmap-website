require "test_helper"

class ChangesetsHelperTest < ActionView::TestCase
  def test_changeset_user_link
    changeset = create(:changeset)
    changeset_user_link_dom = Rails::Dom::Testing.html_document_fragment.parse changeset_user_link(changeset)
    assert_dom changeset_user_link_dom, "a:root", :text => changeset.user.display_name do
      assert_dom "> @href", "/user/#{ERB::Util.u(changeset.user.display_name)}"
    end

    changeset = create(:changeset, :user => create(:user, :data_public => false))
    assert_equal "anonymous", changeset_user_link(changeset)

    changeset = create(:changeset, :user => create(:user, :deleted))
    assert_equal "deleted", changeset_user_link(changeset)
  end

  def test_changeset_details
    changeset = create(:changeset, :created_at => Time.utc(2007, 1, 1, 0, 0, 0), :user => create(:user, :data_public => false))
    # We need to explicitly reset the closed_at to some point in the future, and avoid the before_save callback
    changeset.update_column(:closed_at, Time.now.utc + 1.day) # rubocop:disable Rails/SkipsModelValidations
    changeset_details_dom = Rails::Dom::Testing.html_document_fragment.parse "<div>#{changeset_details(changeset)}</div>"
    assert_dom changeset_details_dom, ":root", :text => /^Created .* by anonymous$/ do
      assert_dom "> time", :count => 1 do
        assert_dom "> @title", "Mon, 01 Jan 2007 00:00:00 +0000"
        assert_dom "> @datetime", "2007-01-01T00:00:00Z"
      end
      assert_dom "> a", :count => 0
    end

    changeset = create(:changeset, :created_at => Time.utc(2007, 1, 1, 0, 0, 0), :closed_at => Time.utc(2007, 1, 2, 0, 0, 0))
    changeset_details_dom = Rails::Dom::Testing.html_document_fragment.parse "<div>#{changeset_details(changeset)}</div>"
    assert_dom changeset_details_dom, ":root", :text => /^Closed .* by #{changeset.user.display_name}$/ do
      assert_dom "> time", :count => 1 do
        assert_dom "> @title", "Created: Mon, 01 Jan 2007 00:00:00 +0000\nClosed: Tue, 02 Jan 2007 00:00:00 +0000"
        assert_dom "> @datetime", "2007-01-02T00:00:00Z"
      end
      assert_dom "> a", :count => 1, :text => changeset.user.display_name do
        assert_dom "> @href", "/user/#{ERB::Util.u(changeset.user.display_name)}"
      end
    end
  end
end
