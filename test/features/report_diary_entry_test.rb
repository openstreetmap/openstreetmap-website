require "test_helper"

class ReportDiaryEntryTest < Capybara::Rails::TestCase
  def setup
    create(:language, :code => "en")
    @diary_entry = create(:diary_entry)
  end

  def test_no_flag_when_not_logged_in
    visit diary_entry_path(@diary_entry.user.display_name, @diary_entry)
    assert page.has_content?(@diary_entry.title)

    assert !page.has_content?("\u2690")
  end

  def test_it_works
    sign_in_as(create(:user))
    visit diary_entry_path(@diary_entry.user.display_name, @diary_entry)
    assert page.has_content? @diary_entry.title

    click_on "\u2690"
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("issues.new.disclaimer.intro")

    choose "report_type__SPAM" # FIXME: use label text when the radio button labels are working
    fill_in "report_details", :with => "This is advertising"
    click_on "Save changes"

    assert page.has_content? "Your report has been registered sucessfully"
  end
end
