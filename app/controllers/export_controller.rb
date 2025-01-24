class ExportController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  before_action :update_totp, :only => [:finish]
  authorize_resource :class => false

  content_security_policy(:only => :embed) do |policy|
    policy.frame_ancestors("*")
  end

  caches_page :embed

  # When the user clicks 'Export' we redirect to a URL which generates the export download
  def finish
    bbox = BoundingBox.from_lon_lat_params(params)
    style = params[:format]
    format = params[:mapnik_format]

    case style
    when "osm"
      # redirect to API map get
      redirect_to api_map_path(:bbox => bbox)

    when "mapnik"
      # redirect to a special 'export' cgi script
      scale = params[:mapnik_scale]

      redirect_to "https://render.openstreetmap.org/cgi-bin/export?bbox=#{bbox}&scale=#{scale}&format=#{format}", :allow_other_host => true
    when "cyclemap", "transportmap"
      zoom = params[:zoom]
      lat = params[:lat]
      lon = params[:lon]
      width = params[:width]
      height = params[:height]

      redirect_to "https://tile.thunderforest.com/static/#{style[..-4]}/#{lon},#{lat},#{zoom}/#{width}x#{height}.#{format}?apikey=#{Settings.thunderforest_key}", :allow_other_host => true
    end
  end

  def embed; end
end
