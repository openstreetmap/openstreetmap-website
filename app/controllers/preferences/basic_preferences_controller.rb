module Preferences
  class BasicPreferencesController < PreferencesController
    private

    def update_preferences
      current_user.languages = [params[:language]]

      current_user.preferred_editor = if params[:user][:preferred_editor] == "default"
                                        nil
                                      else
                                        params[:user][:preferred_editor]
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

      success
    end
  end
end
