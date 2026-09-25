# frozen_string_literal: true

require "application_system_test_case"

class UserNotesTest < ApplicationSystemTestCase
  test "boundary condition when next page link activates" do
    user = create(:user)
    ("A".."J").each do |x|
      create(:note, :author => user, :description => "Note '#{x}'") do |note|
        create(:note_comment, :event => "opened", :note => note, :author => user, :body => "Note '#{x}'")
      end
    end

    visit user_notes_path(user)

    within_content_body do
      assert_text "Note 'J'"
      assert_text "Note 'A'"
      assert_no_link "Previous"
      assert_no_link "Next"
    end

    ("K".."K").each do |x|
      create(:note, :author => user, :description => "Note '#{x}'") do |note|
        create(:note_comment, :event => "opened", :note => note, :author => user, :body => "Note '#{x}'")
      end
    end

    visit user_notes_path(user)

    within_content_body do
      assert_text "Note 'K'"
      assert_text "Note 'B'"
      assert_no_text "Note 'A'"
      assert_no_link "Previous"
      assert_link "Next"

      click_on "Next", :match => :first

      assert_no_text "Note 'K'"
      assert_no_text "Note 'B'"
      assert_text "Note 'A'"
      assert_link "Previous"
      assert_no_link "Next"
    end
  end
end
