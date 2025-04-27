# frozen_string_literal: true

require "application_system_test_case"

class UserLogoutTest < ApplicationSystemTestCase
  test "Sign out via link" do
    user = create(:user)
    sign_in_as(user)
    assert_no_content "Log In"

    click_on user.display_name
    click_on "Log Out"
    assert_content "Log In"
  end

  test "Sign out via link with referer" do
    user = create(:user)
    sign_in_as(user)
    visit traces_path
    assert_no_content "Log In"

    click_on user.display_name
    click_on "Log Out"
    assert_content "Log In"
    assert_content "Public GPS Traces"
  end

  test "Sign out via fallback page" do
    sign_in_as(create(:user))
    assert_no_content "Log In"

    visit logout_path
    assert_content "Logout from OpenStreetMap"

    click_on "Logout"
    assert_content "Log In"
  end

  test "Sign out via fallback page with referer" do
    sign_in_as(create(:user))
    assert_no_content "Log In"

    visit logout_path(:referer => "/traces")
    assert_content "Logout from OpenStreetMap"

    click_on "Logout"
    assert_content "Log In"
    assert_content "Public GPS Traces"
  end

  test "Sign out after navigating diary entries with Turbo pagination" do
    create(:language, :code => "en")
    create(:diary_entry, :title => "First Diary Entry")
    create_list(:diary_entry, 20) # rubocop:disable FactoryBot/ExcessiveCreateList

    check_sign_out_after_turbo_pagination diary_entries_path do
      assert_no_link "First Diary Entry"

      click_on "Older Entries", :match => :first

      assert_link "First Diary Entry"
    end
  end

  test "Sign out after navigating issues with Turbo pagination" do
    first_target_user = create(:user, :display_name => "First Target User")
    create(:issue, :reportable => first_target_user, :reported_user => first_target_user)
    create_list(:issue, 50) # rubocop:disable FactoryBot/ExcessiveCreateList

    check_sign_out_after_turbo_pagination issues_path do
      assert_no_link "First Target User"

      click_on "Older Issues", :match => :first

      assert_link "First Target User"
    end
  end

  test "Sign out after navigating traces with Turbo pagination" do
    create(:trace, :fixture => "a", :name => "First Trace")
    create_list(:trace, 20, :fixture => "a") # rubocop:disable FactoryBot/ExcessiveCreateList

    check_sign_out_after_turbo_pagination traces_path do
      assert_no_link "First Trace"

      click_on "Older Traces", :match => :first

      assert_link "First Trace"
    end
  end

  test "Sign out after navigating changeset comments with Turbo pagination" do
    user = create(:user)
    create(:changeset_comment, :author => user, :body => "First Changeset Comment")
    create_list(:changeset_comment, 20, :author => user) # rubocop:disable FactoryBot/ExcessiveCreateList

    check_sign_out_after_turbo_pagination user_changeset_comments_path(user) do
      assert_no_text "First Changeset Comment"

      click_on "Older Comments", :match => :first

      assert_text "First Changeset Comment"
    end
  end

  test "Sign out after navigating diary comments with Turbo pagination" do
    create(:language, :code => "en")
    user = create(:user)
    create(:diary_comment, :user => user, :body => "First Diary Comment")
    create_list(:diary_comment, 20, :user => user) # rubocop:disable FactoryBot/ExcessiveCreateList

    check_sign_out_after_turbo_pagination user_diary_comments_path(user) do
      assert_no_text "First Diary Comment"

      click_on "Older Comments", :match => :first

      assert_text "First Diary Comment"
    end
  end

  test "Sign out after navigating users with Turbo pagination" do
    create(:user, :display_name => "First User")
    create_list(:user, 50) # rubocop:disable FactoryBot/ExcessiveCreateList

    check_sign_out_after_turbo_pagination users_list_path do
      assert_no_link "First User"

      click_on "Older Users", :match => :first

      assert_link "First User"
    end
  end

  test "Sign out after navigating user blocks with Turbo pagination" do
    check_sign_out_after_turbo_pagination_on_block_pages user_blocks_path
  end

  test "Sign out after navigating issued user blocks with Turbo pagination" do
    creator = create(:moderator_user)
    check_sign_out_after_turbo_pagination_on_block_pages user_issued_blocks_path(creator), :creator => creator
  end

  test "Sign out after navigating received user blocks with Turbo pagination" do
    receiver = create(:user)
    check_sign_out_after_turbo_pagination_on_block_pages user_received_blocks_path(receiver), :receiver => receiver
  end

  private

  def check_sign_out_after_turbo_pagination_on_block_pages(path, receiver: create(:user), creator: create(:moderator_user))
    create(:user_block, :reason => "First User Block", :user => receiver, :creator => creator)
    create_list(:user_block, 20, :user => receiver, :creator => creator) # rubocop:disable FactoryBot/ExcessiveCreateList

    check_sign_out_after_turbo_pagination path do
      assert_no_text "First User Block"

      click_on "Older Blocks", :match => :first

      assert_text "First User Block"
    end
  end

  def check_sign_out_after_turbo_pagination(path, &)
    with_forgery_protection do
      user = create(:super_user)
      sign_in_as user

      visit path

      assert_no_link "Log In"

      within_content_body(&)

      click_on user.display_name
      click_on "Log Out"

      assert_link "Log In"
    end
  end

  def with_forgery_protection
    saved_allow_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    yield
  ensure
    ActionController::Base.allow_forgery_protection = saved_allow_forgery_protection
  end
end
