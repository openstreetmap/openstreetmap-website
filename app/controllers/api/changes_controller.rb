module Api
  class ChangesController < ApiController
    before_action :api_deny_access_handler

    authorize_resource :class => false

    before_action :check_api_readable
    around_action :api_call_handle_error, :api_call_timeout

    # Get a list of the tiles that have changed within a specified time
    # period
    def index
      zoom = (params[:zoom] || "12").to_i

      if params.include?(:start) && params.include?(:end)
        starttime = Time.parse(params[:start])
        endtime = Time.parse(params[:end])
      else
        hours = (params[:hours] || "1").to_i.hours
        endtime = Time.now.getutc
        starttime = endtime - hours
      end

      if zoom >= 1 && zoom <= 16 &&
         endtime > starttime && endtime - starttime <= 24.hours
        mask = (1 << zoom) - 1

        tiles = Node.where(:timestamp => starttime..endtime).group("maptile_for_point(latitude, longitude, #{zoom})").count

        doc = OSM::API.new.get_xml_doc
        changes = XML::Node.new "changes"
        changes["starttime"] = starttime.xmlschema
        changes["endtime"] = endtime.xmlschema

        tiles.each do |tile, count|
          x = (tile.to_i >> zoom) & mask
          y = tile.to_i & mask

          t = XML::Node.new "tile"
          t["x"] = x.to_s
          t["y"] = y.to_s
          t["z"] = zoom.to_s
          t["changes"] = count.to_s

          changes << t
        end

        doc.root << changes

        render :xml => doc.to_s
      else
        render :plain => "Requested zoom is invalid, or the supplied start is after the end time, or the start duration is more than 24 hours", :status => :bad_request
      end
    end
  end
end
