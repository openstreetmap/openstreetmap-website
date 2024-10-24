require "application_system_test_case"

class NoteCommentsTest < ApplicationSystemTestCase
  test "open note has login notice" do
    note = create(:note_with_comments)
    visit note_path(note)

    within_sidebar do
      assert_no_button "Resolve"
      assert_no_button "Comment"
      assert_link "Log in to comment on this note", :href => login_path(:referer => note_path(note))
    end
  end

  test "closed note has no login notice" do
    note = create(:note_with_comments, :closed)
    visit note_path(note)

    within_sidebar do
      assert_no_button "Reactivate"
      assert_no_link "Log in to comment on this note"
    end
  end

  test "can add comment" do
    note = create(:note_with_comments)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)

    within_sidebar do
      assert_no_content "Comment from #{user.display_name}"
      assert_no_content "Some newly added note comment"
      assert_button "Resolve"
      assert_button "Comment", :disabled => true

      fill_in "text", :with => "Some newly added note comment"

      assert_button "Comment & Resolve"
      assert_button "Comment", :disabled => false

      click_on "Comment"

      assert_content "Comment from #{user.display_name}"
      assert_content "Some newly added note comment"
    end
  end

  test "can't add a comment when blocked" do
    note = create(:note_with_comments)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)
    block = create(:user_block, :user => user)

    within_sidebar do
      fill_in "text", :with => "Comment that won't be added while blocked"

      assert_no_text "Comment from #{user.display_name}"
      assert_no_text "Comment that won't be added while blocked"
      assert_no_text "Your access to the API has been blocked"
      assert_button "Comment & Resolve", :disabled => false
      assert_button "Comment", :disabled => false

      click_on "Comment"

      assert_no_text "Comment from #{user.display_name}"
      assert_no_text "Comment that won't be added while blocked"
      assert_text "Your access to the API has been blocked"
      assert_button "Comment & Resolve", :disabled => false
      assert_button "Comment", :disabled => false

      block.revoke! block.creator

      click_on "Comment"

      assert_text "Comment from #{user.display_name}"
      assert_text "Comment that won't be added while blocked"
      assert_no_text "Your access to the API has been blocked"
    end
  end

  test "can't resolve a note when blocked" do
    note = create(:note_with_comments)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)
    create(:user_block, :user => user)

    within_sidebar do
      assert_text "Unresolved note"
      assert_no_text "Resolved note"
      assert_no_text "Your access to the API has been blocked"
      assert_button "Resolve", :disabled => false
      assert_button "Comment", :disabled => true

      click_on "Resolve"

      assert_text "Unresolved note"
      assert_no_text "Resolved note"
      assert_text "Your access to the API has been blocked"
      assert_button "Resolve", :disabled => false
      assert_button "Comment", :disabled => true
    end
  end

  test "can't reactivate a note when blocked" do
    note = create(:note_with_comments, :closed)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)
    create(:user_block, :user => user)

    within_sidebar do
      assert_no_text "Unresolved note"
      assert_text "Resolved note"
      assert_no_text "Your access to the API has been blocked"
      assert_button "Reactivate", :disabled => false

      click_on "Reactivate"

      assert_no_text "Unresolved note"
      assert_text "Resolved note"
      assert_text "Your access to the API has been blocked"
      assert_button "Reactivate", :disabled => false
    end
  end

  test "no subscribe button when not logged in" do
    note = create(:note_with_comments)
    visit note_path(note)

    within_sidebar do
      assert_no_button "Subscribe"
      assert_no_button "Unsubscribe"
    end
  end

  test "can subscribe" do
    note = create(:note_with_comments)
    user = create(:user)
    sign_in_as(user)
    visit note_path(note)

    within_sidebar do
      assert_button "Subscribe"
      assert_no_button "Unsubscribe"

      click_on "Subscribe"

      assert_no_button "Subscribe"
      assert_button "Unsubscribe"
    end
  end

  test "can unsubscribe" do
    note = create(:note_with_comments)
    user = create(:user)
    create(:note_subscription, :note => note, :user => user)
    sign_in_as(user)
    visit note_path(note)

    within_sidebar do
      assert_no_button "Subscribe"
      assert_button "Unsubscribe"

      click_on "Unsubscribe"

      assert_button "Subscribe"
      assert_no_button "Unsubscribe"
    end
  end
end
