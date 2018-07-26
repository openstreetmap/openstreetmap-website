class SiteController < ApplicationController
  layout "site"
  layout :map_layout, :only => [:index, :export]

  before_action :authorize_web
  before_action :set_locale
  before_action :redirect_browse_params, :only => :index
  before_action :redirect_map_params, :only => [:index, :edit, :export]
  before_action :require_user, :only => [:welcome]
  before_action :require_oauth, :only => [:index]
  before_action :update_totp, :only => [:index]

  def index
    session[:location] ||= OSM.ip_location(request.env["REMOTE_ADDR"]) unless STATUS == :database_readonly || STATUS == :database_offline
  end

  def permalink
    lon, lat, zoom = ShortLink.decode(params[:code])
    new_params = params.except(:code, :lon, :lat, :zoom, :layers, :node, :way, :relation, :changeset)

    if new_params.key? :m
      new_params.delete :m
      new_params[:mlat] = lat
      new_params[:mlon] = lon
    end

    if params.key? :node
      new_params[:controller] = "browse"
      new_params[:action] = "node"
      new_params[:id] = params[:node]
    elsif params.key? :way
      new_params[:controller] = "browse"
      new_params[:action] = "way"
      new_params[:id] = params[:way]
    elsif params.key? :relation
      new_params[:controller] = "browse"
      new_params[:action] = "relation"
      new_params[:id] = params[:relation]
    elsif params.key? :changeset
      new_params[:controller] = "browse"
      new_params[:action] = "changeset"
      new_params[:id] = params[:changeset]
    else
      new_params[:controller] = "site"
      new_params[:action] = "index"
    end

    new_params[:anchor] = "map=#{zoom}/#{lat}/#{lon}"
    new_params[:anchor] += "&layers=#{params[:layers]}" if params.key? :layers

    redirect_to new_params.to_unsafe_h
  end

  def key
    expires_in 7.days, :public => true
    render :layout => false
  end

  def edit
    editor = preferred_editor

    if editor == "remote"
      require_oauth
      render :action => :index, :layout => map_layout
      return
    else
      require_user
    end

    if %w[potlatch potlatch2].include?(editor)
      append_content_security_policy_directives(
        :object_src => %w[*],
        :plugin_types => %w[application/x-shockwave-flash],
        :script_src => %w['unsafe-inline']
      )
    end

    if params[:node]
      bbox = Node.find(params[:node]).bbox.to_unscaled
      @lat = bbox.centre_lat
      @lon = bbox.centre_lon
      @zoom = 18
    elsif params[:way]
      bbox = Way.find(params[:way]).bbox.to_unscaled
      @lat = bbox.centre_lat
      @lon = bbox.centre_lon
      @zoom = 17
    elsif params[:note]
      note = Note.find(params[:note])
      @lat = note.lat
      @lon = note.lon
      @zoom = 17
    elsif params[:gpx] && current_user
      trace = Trace.visible_to(current_user).find(params[:gpx])
      @lat = trace.latitude
      @lon = trace.longitude
      @zoom = 16
    end
  end

  def copyright
    @locale = params[:copyright_locale] || I18n.locale
  end

  def welcome; end

  def help; end

  def about; end

  def export; end

  def offline; end

  def preview
    render :html => RichText.new(params[:type], params[:text]).to_html
  end

  def id
    append_content_security_policy_directives(
      :connect_src => %w[*],
      :img_src => %w[* blob:],
      :script_src => %w[dev.virtualearth.net 'unsafe-eval'],
      :style_src => %w['unsafe-inline']
    )

    render "id", :layout => false
  end

  private

  def redirect_browse_params
    if params[:node]
      redirect_to node_path(params[:node])
    elsif params[:way]
      redirect_to way_path(params[:way])
    elsif params[:relation]
      redirect_to relation_path(params[:relation])
    elsif params[:note]
      redirect_to browse_note_path(params[:note])
    elsif params[:query]
      redirect_to search_path(:query => params[:query])
    end
  end

  def redirect_map_params
    anchor = []

    anchor << "map=#{params.delete(:zoom) || 5}/#{params.delete(:lat)}/#{params.delete(:lon)}" if params[:lat] && params[:lon]

    if params[:layers]
      anchor << "layers=#{params.delete(:layers)}"
    elsif params.delete(:notes) == "yes"
      anchor << "layers=N"
    end

    redirect_to params.to_unsafe_h.merge(:anchor => anchor.join("&")) if anchor.present?
  end
end
