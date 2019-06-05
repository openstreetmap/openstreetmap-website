require "application_system_test_case"

class DiaryEntrySystemTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
    @diary_entry = create(:diary_entry)
  end

  test "reply to diary entry should prefill the message subject" do
    sign_in_as(create(:user))
    visit diary_entries_path

    click_on "Reply to this entry"

    assert page.has_content? "Send a new message"
    assert_equal "Re: #{@diary_entry.title}", page.find_field("Subject").value
  end

  test "deleted diary entries should be hidden for regular users" do
    @deleted_entry = create(:diary_entry, :visible => false)

    sign_in_as(create(:user))
    visit diary_entries_path

    assert_not page.has_content? @deleted_entry.title
  end

  test "deleted diary entries should be shown to administrators for review" do
    @deleted_entry = create(:diary_entry, :visible => false)

    sign_in_as(create(:administrator_user))
    visit diary_entries_path

    assert page.has_content? @deleted_entry.title
  end

  test "deleted diary entries should not be shown to admins when the user is also deleted" do
    @deleted_user = create(:user, :status => :deleted)
    @deleted_entry = create(:diary_entry, :visible => false, :user => @deleted_user)

    sign_in_as(create(:administrator_user))
    visit diary_entries_path

    assert_not page.has_content? @deleted_entry.title
  end
end
