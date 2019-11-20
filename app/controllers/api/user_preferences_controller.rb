# Update and read user preferences, which are arbitrayr key/val pairs
module Api
  class UserPreferencesController < ApiController
    before_action :authorize

    authorize_resource

    around_action :api_call_handle_error

    ##
    # return all the preferences as an XML document
    def index
      @user_preferences = current_user.preferences

      render :formats => [:xml]
    end

    ##
    # return the value for a single preference
    def show
      pref = UserPreference.find([current_user.id, params[:preference_key]])

      render :plain => pref.v.to_s
    end

    # update the entire set of preferences
    def update_all
      old_preferences = current_user.preferences.each_with_object({}) do |preference, preferences|
        preferences[preference.k] = preference
      end

      new_preferences = {}

      doc = XML::Parser.string(request.raw_post, :options => XML::Parser::Options::NOERROR).parse

      doc.find("//preferences/preference").each do |pt|
        if preference = old_preferences.delete(pt["k"])
          preference.v = pt["v"]
        elsif new_preferences.include?(pt["k"])
          raise OSM::APIDuplicatePreferenceError, pt["k"]
        else
          preference = current_user.preferences.build(:k => pt["k"], :v => pt["v"])
        end

        new_preferences[preference.k] = preference
      end

      old_preferences.each_value(&:delete)

      new_preferences.each_value(&:save!)

      render :plain => ""
    end

    ##
    # update the value of a single preference
    def update
      begin
        pref = UserPreference.find([current_user.id, params[:preference_key]])
      rescue ActiveRecord::RecordNotFound
        pref = UserPreference.new
        pref.user = current_user
        pref.k = params[:preference_key]
      end

      pref.v = request.raw_post.chomp
      pref.save!

      render :plain => ""
    end

    ##
    # delete a single preference
    def destroy
      UserPreference.find([current_user.id, params[:preference_key]]).delete

      render :plain => ""
    end
  end
end
