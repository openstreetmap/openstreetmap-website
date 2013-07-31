class SiteController < ApplicationController
  layout 'site', :except => [:key, :permalink]
  layout false, :only => [:key, :permalink]

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:edit]
  before_filter :require_oauth, :only => [:index]

  def index
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
      return
    end

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
  end

  def edit
    editor = params[:editor] || @user.preferred_editor || DEFAULT_EDITOR

    if editor == "remote"
      render :action => :index
      return
    end

    @extra_body_class = "site-edit-#{editor}"

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

  def id
    render "id", :layout => false
  end
end
