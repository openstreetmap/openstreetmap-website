# Update and read user preferences, which are arbitrayr key/val pairs
class UserPreferenceController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authorize
  before_action :require_allow_read_prefs, :only => [:read_one, :read]
  before_action :require_allow_write_prefs, :except => [:read_one, :read]
  around_action :api_call_handle_error

  ##
  # return all the preferences as an XML document
  def read
    doc = OSM::API.new.get_xml_doc

    prefs = @user.preferences

    el1 = XML::Node.new "preferences"

    prefs.each do |pref|
      el1 <<  pref.to_xml_node
    end

    doc.root << el1
    render :text => doc.to_s, :content_type => "text/xml"
  end

  ##
  # return the value for a single preference
  def read_one
    pref = UserPreference.find([@user.id, params[:preference_key]])

    render :text => pref.v.to_s, :content_type => "text/plain"
  end

  # update the entire set of preferences
  def update
    old_preferences = @user.preferences.each_with_object({}) do |preference, preferences|
      preferences[preference.k] = preference
    end

    new_preferences = {}

    doc = XML::Parser.string(request.raw_post).parse

    doc.find("//preferences/preference").each do |pt|
      if preference = old_preferences.delete(pt["k"])
        preference.v = pt["v"]
      elsif new_preferences.include?(pt["k"])
        fail OSM::APIDuplicatePreferenceError.new(pt["k"])
      else
        preference = @user.preferences.build(:k => pt["k"], :v => pt["v"])
      end

      new_preferences[preference.k] = preference
    end

    old_preferences.each_value(&:delete)

    new_preferences.each_value(&:save!)

    render :text => "", :content_type => "text/plain"
  end

  ##
  # update the value of a single preference
  def update_one
    begin
      pref = UserPreference.find([@user.id, params[:preference_key]])
    rescue ActiveRecord::RecordNotFound
      pref = UserPreference.new
      pref.user = @user
      pref.k = params[:preference_key]
    end

    pref.v = request.raw_post.chomp
    pref.save!

    render :text => "", :content_type => "text/plain"
  end

  ##
  # delete a single preference
  def delete_one
    UserPreference.find([@user.id, params[:preference_key]]).delete

    render :text => "", :content_type => "text/plain"
  end
end
