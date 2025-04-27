# frozen_string_literal: true

require "application_system_test_case"

class DiaryEntrySystemTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
    create(:language, :code => "pt", :english_name => "Portuguese", :native_name => "Português")
    create(:language, :code => "pt-BR", :english_name => "Brazilian Portuguese", :native_name => "Português do Brasil")
    create(:language, :code => "ru", :english_name => "Russian", :native_name => "Русский")
    @diary_entry = create(:diary_entry)
  end

  test "reply to diary entry should prefill the message subject" do
    sign_in_as(create(:user))
    visit diary_entries_path

    click_on "Send a message to the author"

    assert_content "Send a new message"
    assert_equal "Re: #{@diary_entry.title}", page.find_field("Subject").value
  end

  test "deleted diary entries should be hidden for regular users" do
    @deleted_entry = create(:diary_entry, :visible => false)

    sign_in_as(create(:user))
    visit diary_entries_path

    assert_no_content @deleted_entry.title
  end

  test "deleted diary entries should be shown to administrators for review" do
    @deleted_entry = create(:diary_entry, :visible => false)

    sign_in_as(create(:administrator_user))
    visit diary_entries_path

    assert_content @deleted_entry.title
  end

  test "deleted diary entries should not be shown to admins when the user is also deleted" do
    @deleted_user = create(:user, :deleted)
    @deleted_entry = create(:diary_entry, :visible => false, :user => @deleted_user)

    sign_in_as(create(:administrator_user))
    visit diary_entries_path

    assert_no_content @deleted_entry.title
  end

  test "deleted diary comments should be hidden for regular users" do
    @deleted_comment = create(:diary_comment, :diary_entry => @diary_entry, :visible => false)

    sign_in_as(create(:user))
    visit diary_entry_path(@diary_entry.user, @diary_entry)

    assert_no_content @deleted_comment.body
  end

  test "deleted diary comments should be shown to administrators" do
    @deleted_comment = create(:diary_comment, :diary_entry => @diary_entry, :visible => false)

    sign_in_as(create(:administrator_user))
    visit diary_entry_path(@diary_entry.user, @diary_entry)

    assert_content @deleted_comment.body
  end

  test "should have links to preferred languages" do
    sign_in_as(create(:user, :languages => %w[en-US pt-BR]))
    visit diary_entries_path

    assert_link "Diary Entries in English", :href => "/diary/en"
    assert_link "Diary Entries in Brazilian Portuguese", :href => "/diary/pt-BR"
    assert_link "Diary Entries in Portuguese", :href => "/diary/pt"
    assert_no_link "Diary Entries in Russian"
  end

  test "should have new diary entry link on own diary entry page" do
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user)

    sign_in_as(user)
    visit diary_entry_path(diary_entry.user, diary_entry)

    within_content_heading do
      assert_link "New Diary Entry"
    end
  end

  test "should not have new diary entry link on other user's diary entry page" do
    user = create(:user)
    diary_entry = create(:diary_entry)

    sign_in_as(user)
    visit diary_entry_path(diary_entry.user, diary_entry)

    within_content_heading do
      assert_no_link "New Diary Entry"
    end
  end

  test "should not be hidden on the list page" do
    body = SecureRandom.alphanumeric(1998)
    create(:diary_entry, :body => body)

    visit diary_entries_path

    assert_content body
    assert_no_content I18n.t("diary_entries.diary_entry.full_entry")
  end

  test "should be hidden on the list page" do
    body = SecureRandom.alphanumeric(2000)
    create(:diary_entry, :body => body)

    visit diary_entries_path

    assert_no_content body
    assert_content I18n.t("diary_entries.diary_entry.full_entry")
  end

  test "should be partially hidden on the list page" do
    text1 = "a" * 500
    text2 = "b" * 500
    text3 = "c" * 999
    text4 = "dd"
    text5 = "ff"

    body = "<p>#{text1}</p><div><p>#{text2}</p><p>#{text3}<a href='#'>#{text4}</a></p></div><p>#{text5}</p>"
    create(:diary_entry, :body => body)

    visit diary_entries_path

    assert_content text1
    assert_content text2
    assert_no_content text3
    assert_no_content text4
    assert_no_content text5
    assert_content I18n.t("diary_entries.diary_entry.full_entry")
  end

  test "should not be hidden on the show page" do
    body = SecureRandom.alphanumeric(2001)
    diary_entry = create(:diary_entry, :body => body)

    visit diary_entry_path(diary_entry.user, diary_entry)

    assert_content body
    assert_no_content I18n.t("diary_entries.diary_entry.full_entry")
  end

  test "contents after diary entry should be below floated images" do
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "<img width=100 height=1000 align=left alt='Floated Image'>")

    sign_in_as(user)
    visit diary_entry_path(user, diary_entry)

    img = find "img[alt='Floated Image']"
    assert_link "Edit this entry", :below => img
  end
end
