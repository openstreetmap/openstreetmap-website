class SiteController < ApplicationController
  layout 'site'
  layout :map_layout, :only => [:index, :export]

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :redirect_browse_params, :only => :index
  before_filter :redirect_map_params, :only => [:index, :edit, :export]
  before_filter :require_user, :only => [:edit, :welcome]
  before_filter :require_oauth, :only => [:index]

  def index
    unless STATUS == :database_readonly or STATUS == :database_offline
      session[:location] ||= OSM::IPLocation(request.env['REMOTE_ADDR'])
    end
  end

  def permalink
    lon, lat, zoom = ShortLink::decode(params[:code])
    new_params = params.except(:code, :lon, :lat, :zoom)

    if new_params.has_key? :m
      new_params.delete :m
      new_params[:mlat] = lat
      new_params[:mlon] = lon
    end

    new_params[:controller] = 'site'
    new_params[:action] = 'index'
    new_params[:anchor] = "map=#{zoom}/#{lat}/#{lon}"

    redirect_to new_params
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
    elsif params[:gpx]
      trace = Trace.visible_to(@user).find(params[:gpx])
      @lat = trace.latitude
      @lon = trace.longitude
      @zoom = 16
    end
  end

  def copyright
    @locale = params[:copyright_locale] || I18n.locale
  end

  def welcome
  end

  def help
  end

  def about
  end

  def preview
    render :text => RichText.new(params[:format], params[:text]).to_html
  end

  def id
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

    if params[:lat] && params[:lon]
      anchor << "map=#{params.delete(:zoom) || 5}/#{params.delete(:lat)}/#{params.delete(:lon)}"
    end

    if params[:layers]
      anchor << "layers=#{params.delete(:layers)}"
    elsif params.delete(:notes) == 'yes'
      anchor << "layers=N"
    end

    if anchor.present?
      redirect_to params.merge(:anchor => anchor.join('&'))
    end
  end
end
