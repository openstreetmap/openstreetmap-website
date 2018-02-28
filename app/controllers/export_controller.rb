class ExportController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  before_action :update_totp, :only => [:finish]

  caches_page :embed

  # When the user clicks 'Export' we redirect to a URL which generates the export download
  def finish
    bbox = BoundingBox.from_lon_lat_params(params)
    format = params[:format]

    if format == "osm"
      # redirect to API map get
      redirect_to :controller => "api", :action => "map", :bbox => bbox

    elsif format == "mapnik"
      # redirect to a special 'export' cgi script
      format = params[:mapnik_format]
      scale = params[:mapnik_scale]

      redirect_to "https://render.openstreetmap.org/cgi-bin/export?bbox=#{bbox}&scale=#{scale}&format=#{format}"
    end
  end

  def embed; end
end
