class ExportController < ApplicationController

  before_filter :authorize_web
  before_filter :set_locale

  def start
  end

  #When the user clicks 'Export' we redirect to a URL which generates the export download
  def finish
    bbox = BoundingBox.new(params[:minlon], params[:minlat], params[:maxlon], params[:maxlat])
    format = params[:format]

    if format == "osm"
      #redirect to API map get
      redirect_to "http://api.openstreetmap.org/api/#{API_VERSION}/map?bbox=#{bbox}"

    elsif format == "mapnik"
      #redirect to a special 'export' cgi script
      format = params[:mapnik_format]
      scale = params[:mapnik_scale]

      redirect_to "http://tile.openstreetmap.org/cgi-bin/export?bbox=#{bbox}&scale=#{scale}&format=#{format}"

    elsif format == "osmarender"
      #redirect to the t@h 'MapOf' service
      format = params[:osmarender_format]
      zoom = params[:osmarender_zoom].to_i
      width = bbox.slippy_width(zoom).to_i
      height = bbox.slippy_height(zoom).to_i

      redirect_to "http://tah.openstreetmap.org/MapOf/index.php?long=#{bbox.centre_lon}&lat=#{bbox.centre_lat}&z=#{zoom}&w=#{width}&h=#{height}&format=#{format}"
    end
  end
end
