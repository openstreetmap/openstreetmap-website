# frozen_string_literal: true

require "test_helper"

class ChangesetCommentApiCapabilityTest < ActiveSupport::TestCase
  test "as a normal user without scopes" do
    user = create(:user)
    scopes = Set.new
    ability = ApiAbility.new user, scopes

    assert ability.cannot? :create, ChangesetComment
    assert ability.cannot? :create, :changeset_comment_visibility
    assert ability.cannot? :destroy, :changeset_comment_visibility
  end

  test "as a normal user with write_changeset_comments scope" do
    user = create(:user)
    scopes = Set.new %w[write_changeset_comments]
    ability = ApiAbility.new user, scopes

    assert ability.can? :create, ChangesetComment
    assert ability.cannot? :create, :changeset_comment_visibility
    assert ability.cannot? :destroy, :changeset_comment_visibility
  end

  test "as a moderator without scopes" do
    user = create(:moderator_user)
    scopes = Set.new
    ability = ApiAbility.new user, scopes

    assert ability.cannot? :create, ChangesetComment
    assert ability.cannot? :create, :changeset_comment_visibility
    assert ability.cannot? :destroy, :changeset_comment_visibility
  end

  test "as a moderator with write_changeset_comments scope" do
    user = create(:moderator_user)
    scopes = Set.new %w[write_changeset_comments]
    ability = ApiAbility.new user, scopes

    assert ability.can? :create, ChangesetComment
    assert ability.can? :create, :changeset_comment_visibility
    assert ability.can? :destroy, :changeset_comment_visibility
  end
end

class NoteApiCapabilityTest < ActiveSupport::TestCase
  test "as a normal user without scopes" do
    user = create(:user)
    scopes = Set.new
    ability = ApiAbility.new user, scopes

    [:create, :comment, :close, :reopen, :destroy].each do |action|
      assert ability.cannot? action, Note
    end
  end

  test "as a normal user with write_notes scope" do
    user = create(:user)
    scopes = Set.new %w[write_notes]
    ability = ApiAbility.new user, scopes

    [:destroy].each do |action|
      assert ability.cannot? action, Note
    end

    [:create, :comment, :close, :reopen].each do |action|
      assert ability.can? action, Note
    end
  end

  test "as a moderator without scopes" do
    user = create(:moderator_user)
    scopes = Set.new
    ability = ApiAbility.new user, scopes

    [:destroy].each do |action|
      assert ability.cannot? action, Note
    end
  end

  test "as a moderator with write_notes scope" do
    user = create(:moderator_user)
    scopes = Set.new %w[write_notes]
    ability = ApiAbility.new user, scopes

    [:destroy].each do |action|
      assert ability.can? action, Note
    end
  end
end

class UserApiCapabilityTest < ActiveSupport::TestCase
  test "user preferences" do
    user = create(:user)
    scopes = Set.new
    ability = ApiAbility.new user, scopes

    [:index, :show, :update_all, :update, :destroy].each do |act|
      assert ability.cannot? act, UserPreference
    end

    scopes = Set.new %w[read_prefs]
    ability = ApiAbility.new user, scopes

    [:update_all, :update, :destroy].each do |act|
      assert ability.cannot? act, UserPreference
    end

    [:index, :show].each do |act|
      assert ability.can? act, UserPreference
    end

    scopes = Set.new %w[write_prefs]
    ability = ApiAbility.new user, scopes

    [:index, :show].each do |act|
      assert ability.cannot? act, UserPreference
    end

    [:update_all, :update, :destroy].each do |act|
      assert ability.can? act, UserPreference
    end
  end
end
