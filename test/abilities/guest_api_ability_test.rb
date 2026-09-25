# frozen_string_literal: true

require "test_helper"

class GuestApiAbilityTest < ActiveSupport::TestCase
  test "note permissions for a guest" do
    scopes = Set.new
    ability = ApiAbility.new nil, scopes

    [:index, :create, :feed, :show, :search].each do |action|
      assert ability.can?(action, Note), "should be able to #{action} Notes"
    end

    [:comment, :close, :reopen, :destroy].each do |action|
      assert ability.cannot?(action, Note), "should not be able to #{action} Notes"
    end
  end
end
