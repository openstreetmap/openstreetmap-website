# frozen_string_literal: true

require "test_helper"

module Profiles
  class HeatmapsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/profile/heatmap", :method => :put },
        { :controller => "profiles/heatmaps", :action => "update" }
      )
    end

    def test_update
      user = create(:user, :public_heatmap => true)
      session_for(user)

      heatmap_selector = ".heatmap_frame"

      assert_predicate user.reload, :public_heatmap?
      get user_path(user)
      assert_select heatmap_selector

      put profile_heatmap_path, :params => { :user => { :public_heatmap => "0" } }

      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_dom ".alert-success", :text => "Heatmap updated."

      assert_not_predicate user.reload, :public_heatmap?
      refute_select heatmap_selector

      put profile_heatmap_path, :params => { :user => { :public_heatmap => "1" } }

      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_dom ".alert-success", :text => "Heatmap updated."

      assert_predicate user.reload, :public_heatmap?
      assert_select heatmap_selector
    end
  end
end
