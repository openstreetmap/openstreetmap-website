# Update and read user preferences, which are arbitrary key/val pairs
module Api
  class UserPreferencesController < ApiController
    before_action :authorize

    authorize_resource

    around_action :api_call_handle_error

    before_action :set_request_formats

    ##
    # return all the preferences
    def index
      @user_preferences = current_user.preferences

      respond_to do |format|
        format.xml
        format.json
      end
    end

    ##
    # return the value for a single preference
    def show
      @preference = UserPreference.find([current_user.id, params[:preference_key]])
      # We are setting the default format to xml in api_controller, but this api call used to only return plain text,
      # so the default xml result is incorrect
      if request.format == "application/xml" && (!request.headers["Accept"] || request.headers["Accept"].exclude?("application/xml"))
        render :plain => @preference.v.to_s
      else
        respond_to do |format|
          format.all { render :plain => @preference.v.to_s }
          format.xml
          format.json
        end
      end
    end

    # update the entire set of preferences
    def update_all
      old_preferences = current_user.preferences.index_by(&:k)

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
