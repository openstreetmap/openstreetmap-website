# frozen_string_literal: true

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

  test "can subscribe and unsubscribe after opening the changeset from an element" do
    changeset = create(:changeset, :closed)
    node = create(:node, :changeset => changeset)
    user = create(:user)
    sign_in_as(user)
    visit node_path(node)

    within_sidebar do
      click_on changeset.id.to_s
      assert_comment_can_be_written

      click_on "Subscribe"

      assert_button "Unsubscribe"
      assert_comment_can_be_written

      click_on "Unsubscribe"

      assert_button "Subscribe"
      assert_comment_can_be_written
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

  private

  # Wait until changeset.js init() has run. Only then typing enables Comment.
  def assert_comment_can_be_written
    page.document.synchronize do
      fill_in "text", :with => "x"
      raise Capybara::ExpectationNotMet unless has_button?("Comment", :disabled => false, :wait => 0)
    end
  end
end
