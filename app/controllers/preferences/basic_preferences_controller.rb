# frozen_string_literal: true

module Preferences
  class BasicPreferencesController < PreferencesController
    private

    def update_preferences
      if params[:language] != I18n.locale.to_s
        matching_languages, other_languages = current_user.languages.partition do |language|
          Locale.available.preferred(Locale.list([language]), :default => nil).to_s == params[:language]
        end

        current_user.languages = [params[:language]]

        current_user.languages += (matching_languages - [params[:language]]) + other_languages unless matching_languages.empty?
      end

      if params.dig(:user, :preferred_editor)
        current_user.preferred_editor = if params[:user][:preferred_editor] == "default"
                                          nil
                                        else
                                          params[:user][:preferred_editor]
                                        end
      end

      success = current_user.save

      if params[:site_color_scheme]
        site_color_scheme_preference = current_user.preferences.find_or_create_by(:k => "site.color_scheme")
        success &= site_color_scheme_preference.update(:v => params[:site_color_scheme])
      end

      if params[:map_color_scheme]
        map_color_scheme_preference = current_user.preferences.find_or_create_by(:k => "map.color_scheme")
        success &= map_color_scheme_preference.update(:v => params[:map_color_scheme])
      end

      if params[:editor_color_scheme]
        editor_color_scheme_preference = current_user.preferences.find_or_create_by(:k => "editor.color_scheme")
        success &= editor_color_scheme_preference.update(:v => params[:editor_color_scheme])
      end

      success
    end
  end
end
