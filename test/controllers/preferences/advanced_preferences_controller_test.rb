# frozen_string_literal: true

require "test_helper"

module Preferences
  class AdvancedPreferencesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/preferences/advanced", :method => :get },
        { :controller => "preferences/advanced_preferences", :action => "show" }
      )
      assert_routing(
        { :path => "/preferences/advanced", :method => :put },
        { :controller => "preferences/advanced_preferences", :action => "update" }
      )
    end

    def test_update_languages
      I18n.with_locale "en" do
        user = create(:user, :languages => [])
        session_for(user)

        put advanced_preferences_path, :params => { :user => { :preferred_editor => "id", :languages => "fr es en" } }

        assert_redirected_to advanced_preferences_path
        follow_redirect!
        assert_template :show
        assert_select ".alert-success", /^Préférences mises à jour/
        user.reload
        assert_equal %w[fr es en], user.languages
      end
    end
  end
end
