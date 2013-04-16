class SiteController < ApplicationController
  layout 'site', :except => [:key, :permalink]
  layout false, :only => [:key, :permalink]

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:edit]
  before_filter :require_oauth, :only => [:index]

  def index
    unless STATUS == :database_readonly or STATUS == :database_offline
      session[:location] ||= OSM::IPLocation(request.env['REMOTE_ADDR'])
    end
  end

  def permalink
    lon, lat, zoom = ShortLink::decode(params[:code])
    new_params = params.clone
    new_params.delete :code
    if new_params.has_key? :m
      new_params.delete :m
      new_params[:mlat] = lat
      new_params[:mlon] = lon
    else
      new_params[:lat] = lat
      new_params[:lon] = lon
    end
    new_params[:zoom] = zoom
    new_params[:controller] = 'site'
    new_params[:action] = 'index'
    redirect_to new_params
  end

  def key
    expires_in 7.days, :public => true
  end

  def edit
    editor = params[:editor] || @user.preferred_editor || DEFAULT_EDITOR

    if editor == "remote"
      render :action => :index
      return
    end

    if params[:node]
      bbox = Node.find(params[:node]).bbox.to_unscaled
      @lat = bbox.centre_lat
      @lon = bbox.centre_lon
    elsif params[:way]
      bbox = Way.find(params[:way]).bbox.to_unscaled
      @lat = bbox.centre_lat
      @lon = bbox.centre_lon
    elsif params[:gpx]
      trace = Trace.visible_to(@user).find(params[:gpx])
      @lat = trace.latitude
      @lon = trace.longitude
    end
  end

  def copyright
    @locale = params[:copyright_locale] || I18n.locale
  end

  def preview
    render :text => RichText.new(params[:format], params[:text]).to_html
  end
end
