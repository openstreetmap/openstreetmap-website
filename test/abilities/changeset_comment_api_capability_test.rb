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
