# frozen_string_literal: true

require "test_helper"

module Preferences
  class BasicPreferencesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/preferences/basic", :method => :get },
        { :controller => "preferences/basic_preferences", :action => "show" }
      )
      assert_routing(
        { :path => "/preferences/basic", :method => :put },
        { :controller => "preferences/basic_preferences", :action => "update" }
      )

      get "/preferences"
      assert_redirected_to "/preferences/basic"

      get "/preferences/edit"
      assert_redirected_to "/preferences/basic"
    end

    def test_update_preferred_editor
      user = create(:user, :languages => [])
      user.preferences.create(:k => "site.color_scheme", :v => "light")
      user.preferences.create(:k => "map.color_scheme", :v => "light")
      user.preferences.create(:k => "editor.color_scheme", :v => "light")
      session_for(user)

      # Changing to a invalid editor should fail
      put basic_preferences_path, :params => { :user => { :preferred_editor => "unknown" } }
      assert_response :success
      assert_template :show
      assert_select ".alert-success", false
      assert_select ".alert-danger", true
      user.reload
      assert_nil user.preferred_editor
      assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v
      assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v
      assert_equal "light", user.preferences.find_by(:k => "editor.color_scheme")&.v

      # Changing to a valid editor should work
      put basic_preferences_path, :params => { :user => { :preferred_editor => "id" } }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      user.reload
      assert_equal "id", user.preferred_editor
      assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v
      assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v
      assert_equal "light", user.preferences.find_by(:k => "editor.color_scheme")&.v

      # Changing to the default editor should work
      put basic_preferences_path, :params => { :user => { :preferred_editor => "default" } }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      user.reload
      assert_nil user.preferred_editor
      assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v
      assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v
      assert_equal "light", user.preferences.find_by(:k => "editor.color_scheme")&.v
    end

    def test_update_with_referer
      session_for(create(:user))
      put basic_preferences_path, :params => { :referer => root_path }
      assert_redirected_to root_path
    end

    def test_update_preferred_language_from_en_selecting_fr
      check_language_change %w[en], "fr", %w[fr]
    end

    def test_update_preferred_language_from_unknown_selecting_fr
      check_language_change %w[unknown], "fr", %w[fr]
    end

    def test_update_preferred_language_from_unknown_en_selecting_en
      check_language_change %w[unknown en], "en", %w[unknown en]
    end

    def test_update_preferred_language_from_unknown_en_selecting_fr
      check_language_change %w[unknown en], "fr", %w[fr]
    end

    def test_update_preferred_language_from_en_unknown_selecting_fr
      check_language_change %w[en unknown], "fr", %w[fr]
    end

    def test_update_preferred_language_from_ru_en_selecting_en
      check_language_change %w[ru en], "en", %w[en ru]
    end

    def test_update_preferred_language_from_fr_enau_selecting_en
      check_language_change %w[fr en-AU], "en", %w[en en-AU fr]
    end

    def test_update_preferred_language_from_fr_enau_en_selecting_en
      check_language_change %w[fr en-AU en], "en", %w[en en-AU fr]
    end

    def test_update_preferred_language_from_fr_es_selecting_de
      check_language_change %w[fr es], "de", %w[de]
    end

    def test_update_preferred_site_color_scheme
      user = create(:user, :languages => [])
      session_for(user)
      assert_nil user.preferences.find_by(:k => "site.color_scheme")

      # Changing when previously not defined
      put basic_preferences_path, :params => { :user => user.attributes, :site_color_scheme => "light" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v

      # Changing when previously defined
      put basic_preferences_path, :params => { :user => user.attributes, :site_color_scheme => "auto" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "auto", user.preferences.find_by(:k => "site.color_scheme")&.v
    end

    def test_update_preferred_map_color_scheme
      user = create(:user, :languages => [])
      session_for(user)
      assert_nil user.preferences.find_by(:k => "map.color_scheme")

      # Changing when previously not defined
      put basic_preferences_path, :params => { :user => user.attributes, :map_color_scheme => "light" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v

      # Changing when previously defined
      put basic_preferences_path, :params => { :user => user.attributes, :map_color_scheme => "auto" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "auto", user.preferences.find_by(:k => "map.color_scheme")&.v
    end

    def test_update_preferred_editor_color_scheme
      user = create(:user, :languages => [])
      session_for(user)
      assert_nil user.preferences.find_by(:k => "editor.color_scheme")

      # Changing when previously not defined
      put basic_preferences_path, :params => { :user => user.attributes, :editor_color_scheme => "light" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "light", user.preferences.find_by(:k => "editor.color_scheme")&.v

      # Changing when previously defined
      put basic_preferences_path, :params => { :user => user.attributes, :editor_color_scheme => "auto" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "auto", user.preferences.find_by(:k => "editor.color_scheme")&.v
    end

    private

    def check_language_change(from_languages, selecting_language, to_languages)
      I18n.with_locale "en" do
        user = create(:user, :preferred_editor => "remote", :languages => from_languages)
        another_user = create(:user, :languages => %w[not going to change])
        session_for(user)

        put basic_preferences_path, :params => { :language => selecting_language }

        assert_redirected_to basic_preferences_path
        user.reload
        assert_equal to_languages, user.languages
        assert_equal "remote", user.preferred_editor
        another_user.reload
        assert_equal %w[not going to change], another_user.languages
      end
    end
  end
end
