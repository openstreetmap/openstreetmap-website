require "application_system_test_case"

class RedactionDestroyTest < ApplicationSystemTestCase
  test "fails to delete nonempty redaction" do
    redaction = create(:redaction, :title => "Some-unwanted-data-redaction")
    create(:old_node, :redaction => redaction)

    sign_in_as create(:moderator_user)
    visit redaction_path(redaction)
    assert_text "Some-unwanted-data-redaction"

    accept_alert do
      click_on "Remove this redaction"
    end
    assert_text "Redaction is not empty"
    assert_text "Some-unwanted-data-redaction"
  end

  test "deletes empty redaction" do
    redaction = create(:redaction, :title => "No-unwanted-data-redaction")

    sign_in_as create(:moderator_user)
    visit redaction_path(redaction)
    assert_text "No-unwanted-data-redaction"

    accept_alert do
      click_on "Remove this redaction"
    end
    assert_text "Redaction destroyed"
    assert_text "List of Redactions"
    assert_no_text "No-unwanted-data-redaction"
  end
end
