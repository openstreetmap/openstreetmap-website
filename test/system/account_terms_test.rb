# frozen_string_literal: true

require "application_system_test_case"

class AccountTermsTest < ApplicationSystemTestCase
  test "should inform about terms if not agreed" do
    user = create(:user, :terms_seen => true, :terms_agreed => nil, :tou_agreed => nil)

    sign_in_as(user)
    visit account_path

    within_content_body do
      assert_text(/You have not yet agreed to.*Contributor Terms/)
      assert_text(/You have not yet agreed to.*Terms of Use/)
      assert_link "Review and accept the Terms"

      click_on "Review and accept the Terms", :match => :first
    end

    assert_current_path account_terms_path
  end

  test "should inform about terms if partially agreed" do
    user = create(:user, :terms_seen => true, :terms_agreed => "2022-03-14", :tou_agreed => nil)

    sign_in_as(user)
    visit account_path

    within_content_body do
      assert_text(/You agreed to.*Contributor Terms.*March 14, 2022/)
      assert_text(/You have not yet agreed to.*Terms of Use/)
      assert_link "Review the Terms"
      assert_link "Review and accept the Terms"

      click_on "Review and accept the Terms", :match => :first
    end

    assert_current_path account_terms_path
  end

  test "should inform about terms if agreed" do
    user = create(:user, :terms_seen => true, :terms_agreed => "2023-04-15", :tou_agreed => "2024-05-16")

    sign_in_as(user)
    visit account_path

    within_content_body do
      assert_text(/You agreed to.*Contributor Terms.*April 15, 2023/)
      assert_text(/You agreed to.*Terms of Use.*May 16, 2024/)
      assert_link "Review the Terms"

      click_on "Review the Terms", :match => :first
    end

    assert_current_path account_terms_path
  end

  test "should ask to consider pd if not considered" do
    user = create(:user, :consider_pd => false)

    sign_in_as(user)
    visit account_path

    within_content_body do
      assert_text(/You haven't declared.*Public Domain/)
      assert_link "Consider Public Domain"

      click_on "Consider Public Domain"
    end

    assert_current_path account_pd_declaration_path
  end

  test "should not ask to consider pd if considered" do
    user = create(:user, :consider_pd => true)

    sign_in_as(user)
    visit account_path

    within_content_body do
      assert_text(/You have also declared.*Public Domain/)
      assert_no_link "Consider Public Domain"
    end
  end
end
