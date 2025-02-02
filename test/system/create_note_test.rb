require "application_system_test_case"

class CreateNoteTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  def setup
    OmniAuth.config.test_mode = true

    stub_request(:get, /.*gravatar.com.*d=404/).to_return(:status => 404)
  end

  def teardown
    OmniAuth.config.mock_auth[:google] = nil
    OmniAuth.config.test_mode = false
  end

  test "can create note" do
    visit new_note_path(:anchor => "map=18/0/0")

    within_sidebar do
      assert_button "Add Note", :disabled => true

      fill_in "text", :with => "Some newly added note description"
      click_on "Add Note"

      assert_content "Unresolved note #"
      assert_content "Some newly added note description"
    end
  end

  test "cannot create new note when zoomed out" do
    visit new_note_path(:anchor => "map=12/0/0")

    within_sidebar do
      assert_no_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => true

      fill_in "text", :with => "Some newly added note description"

      assert_no_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => false
    end

    find(".control-button.zoomout").click

    within_sidebar do
      assert_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => true
    end

    find(".control-button.zoomin").click

    within_sidebar do
      assert_no_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => false

      click_on "Add Note"

      assert_content "Unresolved note #"
      assert_content "Some newly added note description"
    end
  end

  test "can open new note page when zoomed out" do
    visit new_note_path(:anchor => "map=11/0/0")

    within_sidebar do
      assert_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => true

      fill_in "text", :with => "Some newly added note description"

      assert_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => true
    end

    find(".control-button.zoomin").click

    within_sidebar do
      assert_no_content "Zoom in to add a note"
      assert_button "Add Note", :disabled => false
    end
  end

  test "cannot create note when api is readonly" do
    with_settings(:status => "api_readonly") do
      visit new_note_path(:anchor => "map=18/0/0")

      within_sidebar do
        assert_no_button "Add Note", :disabled => true
      end
    end
  end

  test "encouragement to contribute appears after 10 created notes and disappears after login" do
    check_encouragement_while_creating_notes(10)

    sign_in_as(create(:user))

    check_no_encouragement_while_logging_out
  end

  test "encouragement to contribute appears after 10 created notes and disappears after email signup" do
    check_encouragement_while_creating_notes(10)

    sign_up_with_email

    check_no_encouragement_while_logging_out
  end

  test "encouragement to contribute appears after 10 created notes and disappears after google signup" do
    check_encouragement_while_creating_notes(10)

    sign_up_with_google

    check_no_encouragement_while_logging_out
  end

  private

  def check_encouragement_while_creating_notes(encouragement_threshold)
    encouragement_threshold.times do |n|
      visit new_note_path(:anchor => "map=16/0/#{0.001 * n}")

      within_sidebar do
        assert_no_content(/already posted at least \d+ anonymous note/)

        fill_in "text", :with => "new note ##{n + 1}"
        click_on "Add Note"

        assert_content "new note ##{n + 1}"
      end
    end

    visit new_note_path(:anchor => "map=16/0/#{0.001 * encouragement_threshold}")

    within_sidebar do
      assert_content(/already posted at least #{encouragement_threshold} anonymous note/)
    end
  end

  def check_no_encouragement_while_logging_out
    visit new_note_path(:anchor => "map=16/0/0")

    within_sidebar do
      assert_no_content(/already posted at least \d+ anonymous note/)
    end

    sign_out
    visit new_note_path(:anchor => "map=16/0/0")

    within_sidebar do
      assert_no_content(/already posted at least \d+ anonymous note/)
    end
  end

  def sign_up_with_email
    click_on "Sign Up"

    within_content_body do
      fill_in "Email", :with => "new_user_account@example.com"
      fill_in "Display Name", :with => "new_user_account"
      fill_in "Password", :with => "new_user_password"
      fill_in "Confirm Password", :with => "new_user_password"

      assert_emails 1 do
        click_on "Sign Up"
      end
    end

    email = ActionMailer::Base.deliveries.first
    email_text = email.parts[0].parts[0].decoded
    match = %r{/user/new_user_account/confirm\?confirm_string=\S+}.match(email_text)
    assert_not_nil match

    visit match[0]

    assert_content "Welcome!"
  end

  def sign_up_with_google
    OmniAuth.config.add_mock(:google,
                             :uid => "123454321",
                             :extra => { :id_info => { :openid_id => "http://localhost:1123/new.tester" } },
                             :info => { :email => "google_user_account@example.com", :name => "google_user_account" })

    click_on "Sign Up"

    within_content_body do
      click_on "Log in with Google"
      click_on "Sign Up"
    end
  end
end
