require "application_system_test_case"

class ChangesetCommentsTest < ApplicationSystemTestCase
  test "open changeset has a still open notice" do
    changeset = create(:changeset)
    sign_in_as(create(:user))
    visit changeset_path(changeset)

    within_sidebar do
      assert_no_button "Comment"
      assert_text "Changeset still open"
    end
  end

  test "changeset has a login notice" do
    changeset = create(:changeset, :closed)
    visit changeset_path(changeset)

    within_sidebar do
      assert_no_button "Subscribe"
      assert_no_button "Comment"
      assert_link "Log in to join the discussion", :href => login_path(:referer => changeset_path(changeset))
    end
  end

  test "can add a comment to a changeset" do
    changeset = create(:changeset, :closed)
    user = create(:user)
    sign_in_as(user)
    visit changeset_path(changeset)

    within_sidebar do
      assert_no_content "Comment from #{user.display_name}"
      assert_no_content "Some newly added changeset comment"
      assert_button "Comment", :disabled => true

      fill_in "text", :with => "Some newly added changeset comment"

      assert_button "Comment", :disabled => false

      click_on "Comment"

      assert_content "Comment from #{user.display_name}"
      assert_content "Some newly added changeset comment"
    end
  end
end
