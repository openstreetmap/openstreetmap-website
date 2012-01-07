# Update and read user preferences, which are arbitrayr key/val pairs
class UserPreferenceController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authorize
  before_filter :require_allow_read_prefs, :only => [:read_one, :read]
  before_filter :require_allow_write_prefs, :except => [:read_one, :read]

  def read_one
    pref = UserPreference.find(@user.id, params[:preference_key])

    render :text => pref.v.to_s
  rescue ActiveRecord::RecordNotFound => ex
    render :text => 'OH NOES! PREF NOT FOUND!', :status => :not_found
  end

  def update_one
    begin
      pref = UserPreference.find(@user.id, params[:preference_key])
      pref.v = request.raw_post.chomp
      pref.save
    rescue ActiveRecord::RecordNotFound 
      pref = UserPreference.new
      pref.user = @user
      pref.k = params[:preference_key]
      pref.v = request.raw_post.chomp
      pref.save
    end

    render :nothing => true
  end

  def delete_one
    UserPreference.delete(@user.id, params[:preference_key])

    render :nothing => true
  rescue ActiveRecord::RecordNotFound => ex
    render :text => "param: #{params[:preference_key]} not found", :status => :not_found
  end

  # print out all the preferences as a big xml block
  def read
    doc = OSM::API.new.get_xml_doc

    prefs = @user.preferences

    el1 = XML::Node.new 'preferences'

    prefs.each do |pref|
      el1 <<  pref.to_xml_node
    end

    doc.root << el1
    render :text => doc.to_s, :content_type => "text/xml"
  end

  # update the entire set of preferences
  def update
    begin
      p = XML::Parser.string(request.raw_post)
    rescue LibXML::XML::Error, ArgumentError => ex
      raise OSM::APIBadXMLError.new("preferences", xml, ex.message)
    end
    doc = p.parse

    prefs = []

    keyhash = {}

    doc.find('//preferences/preference').each do |pt|
      pref = UserPreference.new

      unless keyhash[pt['k']].nil? # already have that key
        render :text => 'OH NOES! CAN HAS UNIQUE KEYS?', :status => :not_acceptable
      end

      keyhash[pt['k']] = 1

      pref.k = pt['k']
      pref.v = pt['v']
      pref.user_id = @user.id
      prefs << pref
    end

    if prefs.size > 150
      render :text => 'Too many preferences', :status => :request_entity_too_large
    end

    # kill the existing ones
    UserPreference.delete_all(['user_id = ?', @user.id])

    # save the new ones
    prefs.each do |pref|
      pref.save!
    end
    render :nothing => true

  rescue Exception => ex
    render :text => 'OH NOES! FAIL!: ' + ex.to_s, :status => :internal_server_error
  end
end
