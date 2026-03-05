# frozen_string_literal: true

require "test_helper"

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
