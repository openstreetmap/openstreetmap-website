# frozen_string_literal: true

module Searches
  class NominatimQueriesController < QueriesController
    include NominatimMethods

    def create
      # ask nominatim
      response = fetch_xml(nominatim_query_url(:format => "xml"))

      # extract the results from the response
      results = response.elements["searchresults"]

      # create result array
      @results = []

      # create parameter hash for "more results" link
      @more_params = params
                     .permit(:query, :minlon, :minlat, :maxlon, :maxlat, :exclude)
                     .merge(:exclude => results.attributes["exclude_place_ids"])

      # parse the response
      results.elements.each("place") do |place|
        lat = place.attributes["lat"]
        lon = place.attributes["lon"]
        klass = place.attributes["class"]
        type = place.attributes["type"]
        name = place.attributes["display_name"]
        min_lat, max_lat, min_lon, max_lon = place.attributes["boundingbox"].split(",")
        prefix_name = if type.empty?
                        ""
                      else
                        t "geocoder.search_osm_nominatim.prefix.#{klass}.#{type}", :default => type.tr("_", " ").capitalize
                      end
        if klass == "boundary" && type == "administrative"
          rank = (place.attributes["address_rank"].to_i + 1) / 2
          prefix_name = t "geocoder.search_osm_nominatim.admin_levels.level#{rank}", :default => prefix_name
          border_type = nil
          place_type = nil
          place_tags = %w[linked_place place]
          place.elements["extratags"].elements.each("tag") do |extratag|
            border_type = t "geocoder.search_osm_nominatim.border_types.#{extratag.attributes['value']}", :default => border_type if extratag.attributes["key"] == "border_type"
            place_type = t "geocoder.search_osm_nominatim.prefix.place.#{extratag.attributes['value']}", :default => place_type if place_tags.include?(extratag.attributes["key"])
          end
          prefix_name = place_type || border_type || prefix_name
        end
        prefix = t "geocoder.search_osm_nominatim.prefix_format", :name => prefix_name
        object_type = place.attributes["osm_type"]
        object_id = place.attributes["osm_id"]

        @results.push(:lat => lat, :lon => lon,
                      :min_lat => min_lat, :max_lat => max_lat,
                      :min_lon => min_lon, :max_lon => max_lon,
                      :prefix => prefix, :name => name,
                      :type => object_type, :id => object_id)
      end
    rescue StandardError => e
      host = URI(Settings.nominatim_url).host
      @error = "Error contacting #{host}: #{e}"
      render :action => "error"
    end
  end
end
