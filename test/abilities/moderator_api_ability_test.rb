# frozen_string_literal: true

require "test_helper"

class ModeratorApiAbilityTest < ActiveSupport::TestCase
  test "Note permissions" do
    user = create(:moderator_user)
    scopes = Set.new %w[write_notes]
    ability = ApiAbility.new user, scopes

    [:index, :create, :comment, :feed, :show, :search, :close, :reopen, :destroy].each do |action|
      assert ability.can?(action, Note), "should be able to #{action} Notes"
    end
  end
end
