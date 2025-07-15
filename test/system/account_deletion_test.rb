require "application_system_test_case"

class AccountDeletionTest < ApplicationSystemTestCase
  def setup
    @user = create(:user, :display_name => "test user")
    sign_in_as(@user)
  end

  test "the status is deleted and the personal data removed" do
    visit account_path

    click_on "Delete Account..."
    accept_confirm do
      click_on "Delete Account"
    end

    assert_current_path root_path
    @user.reload
    assert_equal "deleted", @user.status
    assert_equal "user_#{@user.id}", @user.display_name
  end

  test "the user is signed out after deletion" do
    visit account_path

    click_on "Delete Account..."
    accept_confirm do
      click_on "Delete Account"
    end

    assert_content "Log In"
  end

  test "the user is shown a confirmation flash message" do
    visit account_path

    click_on "Delete Account..."
    accept_confirm do
      click_on "Delete Account"
    end

    assert_content "Account Deleted"
  end

  test "can delete with any delay setting value if the user has no changesets" do
    with_user_account_deletion_delay(10000) do
      travel 1.hour do
        visit account_path

        click_on "Delete Account..."

        assert_no_content "cannot currently be deleted"
      end
    end
  end

  test "can delete with delay disabled" do
    with_user_account_deletion_delay(nil) do
      create(:changeset, :user => @user)

      travel 1.hour do
        visit account_path

        click_on "Delete Account..."

        assert_no_content "cannot currently be deleted"
      end
    end
  end

  test "can delete when last changeset is old enough" do
    with_user_account_deletion_delay(10) do
      create(:changeset, :user => @user, :created_at => Time.now.utc, :closed_at => Time.now.utc + 1.hour)

      travel 12.hours do
        visit account_path

        click_on "Delete Account..."

        assert_no_content "cannot currently be deleted"
      end
    end
  end

  test "can't delete when last changeset isn't old enough" do
    with_user_account_deletion_delay(10) do
      create(:changeset, :user => @user, :created_at => Time.now.utc, :closed_at => Time.now.utc + 1.hour)

      travel 10.hours do
        visit account_path

        click_on "Delete Account..."

        assert_content "cannot currently be deleted"
        assert_content "in about 1 hour"
      end
    end
  end
end
