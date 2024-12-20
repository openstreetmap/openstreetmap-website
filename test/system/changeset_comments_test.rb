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

  test "regular users can't hide comments" do
    changeset = create(:changeset, :closed)
    create(:changeset_comment, :changeset => changeset, :body => "Unwanted comment")
    sign_in_as(create(:user))
    visit changeset_path(changeset)

    within_sidebar do
      assert_text "Unwanted comment"
      assert_no_button "hide"
    end
  end

  test "moderators can hide comments" do
    changeset = create(:changeset, :closed)
    create(:changeset_comment, :changeset => changeset, :body => "Unwanted comment")

    visit changeset_path(changeset)

    within_sidebar do
      assert_text "Unwanted comment"
    end

    sign_in_as(create(:moderator_user))
    visit changeset_path(changeset)

    within_sidebar do
      assert_text "Unwanted comment"
      assert_button "hide", :exact => true
      assert_no_button "unhide", :exact => true

      click_on "hide", :exact => true

      assert_text "Unwanted comment"
      assert_no_button "hide", :exact => true
      assert_button "unhide", :exact => true
    end

    sign_out
    visit changeset_path(changeset)

    within_sidebar do
      assert_no_text "Unwanted comment"
    end
  end

  test "moderators can unhide comments" do
    changeset = create(:changeset, :closed)
    create(:changeset_comment, :changeset => changeset, :body => "Wanted comment", :visible => false)

    visit changeset_path(changeset)

    within_sidebar do
      assert_no_text "Wanted comment"
    end

    sign_in_as(create(:moderator_user))
    visit changeset_path(changeset)

    within_sidebar do
      assert_text "Wanted comment"
      assert_no_button "hide", :exact => true
      assert_button "unhide", :exact => true

      click_on "unhide", :exact => true

      assert_text "Wanted comment"
      assert_button "hide", :exact => true
      assert_no_button "unhide", :exact => true
    end

    sign_out
    visit changeset_path(changeset)

    within_sidebar do
      assert_text "Wanted comment"
    end
  end

  test "can subscribe" do
    changeset = create(:changeset, :closed)
    user = create(:user)
    sign_in_as(user)
    visit changeset_path(changeset)

    within_sidebar do
      assert_button "Subscribe"
      assert_no_button "Unsubscribe"

      click_on "Subscribe"

      assert_no_button "Subscribe"
      assert_button "Unsubscribe"
    end
  end

  test "can't subscribe when blocked" do
    changeset = create(:changeset, :closed)
    user = create(:user)
    sign_in_as(user)
    visit changeset_path(changeset)
    create(:user_block, :user => user)

    within_sidebar do
      assert_no_text "Your access to the API has been blocked"
      assert_button "Subscribe"
      assert_no_button "Unsubscribe"

      click_on "Subscribe"

      assert_text "Your access to the API has been blocked"
      assert_button "Subscribe"
      assert_no_button "Unsubscribe"
    end
  end
end
