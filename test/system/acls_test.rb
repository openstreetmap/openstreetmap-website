# frozen_string_literal: true

require "application_system_test_case"

class AclsTest < ApplicationSystemTestCase
  test "index shows a placeholder when there are no acls" do
    sign_in_as(create(:administrator_user))

    visit acls_path
    assert_title "ACLs"
    assert_text "No ACLs to show."
  end

  test "index lists acls with formatted addresses" do
    create(:acl, :address => "192.0.2.0/24", :k => "no_account_creation", :v => "spam")
    create(:acl, :address => "198.51.100.7", :k => "no_note_comment")
    create(:acl, :domain => "example.com", :mx => "mail.example.com", :k => "allow_account_creation")
    sign_in_as(create(:administrator_user))

    visit acls_path
    within_table "acl_list" do
      assert_selector "tbody tr", :count => 3
      assert_selector "tr", :text => "192.0.2.0/24 no_account_creation spam"
      assert_selector "tr", :text => "198.51.100.7 no_note_comment"
      assert_selector "tr", :text => "example.com mail.example.com allow_account_creation"
    end
  end

  test "create an acl" do
    sign_in_as(create(:administrator_user))

    visit acls_path
    click_on "New ACL"
    assert_title "New ACL"

    fill_in "Address", :with => "192.0.2.0/24"
    fill_in "Domain", :with => "example.com"
    fill_in "MX server", :with => "mail.example.com"
    fill_in "Key", :with => "no_account_creation"
    fill_in "Value", :with => "spam"
    click_on "Create ACL"

    assert_text "ACL created."
    within_table "acl_list" do
      assert_selector "tr", :text => "192.0.2.0/24 example.com mail.example.com no_account_creation spam"
    end
  end

  test "create an acl with an invalid address" do
    sign_in_as(create(:administrator_user))

    visit new_acl_path
    fill_in "Address", :with => "not-an-address"
    fill_in "Key", :with => "no_account_creation"
    click_on "Create ACL"

    assert_title "New ACL"
    assert_text "is invalid"
    assert_field "Address", :with => "not-an-address"
    assert_equal 0, Acl.count
  end

  test "edit an acl" do
    create(:acl, :address => "192.0.2.0/24", :k => "no_account_creation")
    sign_in_as(create(:administrator_user))

    visit acls_path
    within_table "acl_list" do
      click_on "Edit"
    end
    assert_title "Editing ACL"
    assert_field "Address", :with => "192.0.2.0/24"
    assert_field "Key", :with => "no_account_creation"

    fill_in "Address", :with => "198.51.100.7"
    fill_in "Key", :with => "no_note_comment"
    click_on "Update ACL"

    assert_text "ACL updated."
    within_table "acl_list" do
      assert_selector "tr", :text => "198.51.100.7 no_note_comment"
      assert_no_text "192.0.2.0/24"
    end
  end

  test "delete an acl" do
    create(:acl, :address => "192.0.2.0/24", :k => "no_account_creation")
    sign_in_as(create(:administrator_user))

    visit acls_path
    accept_confirm do
      click_on "Delete"
    end

    assert_text "ACL deleted."
    assert_text "No ACLs to show."
    assert_equal 0, Acl.count
  end
end
