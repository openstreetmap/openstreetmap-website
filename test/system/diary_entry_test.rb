require "application_system_test_case"

class DiaryEntrySystemTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
    @diary_entry = create(:diary_entry)
  end

  test "reply to diary entry should prefill the message subject" do
    sign_in_as(create(:user))
    visit diary_path

    click_on "Reply to this entry"

    assert page.has_content? "Send a new message"
    assert_equal "Re: #{@diary_entry.title}", page.find_field("Subject").value
  end
end
