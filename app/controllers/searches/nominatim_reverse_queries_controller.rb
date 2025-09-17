# frozen_string_literal: true

module Searches
  class NominatimReverseQueriesController < QueriesController
    include NominatimMethods

    def create
      # get query parameters
      zoom = params[:zoom]

      # create result array
      @results = []

      # ask nominatim
      response = fetch_xml(nominatim_reverse_query_url(:format => "xml"))

      # parse the response
      response.elements.each("reversegeocode/result") do |result|
        lat = result.attributes["lat"]
        lon = result.attributes["lon"]
        object_type = result.attributes["osm_type"]
        object_id = result.attributes["osm_id"]
        description = result.text

        @results.push(:lat => lat, :lon => lon,
                      :zoom => zoom,
                      :name => description,
                      :type => object_type, :id => object_id)

        respond_to do |format|
          format.html
          format.json { render :json => @results }
        end
      end
    rescue StandardError => e
      host = URI(Settings.nominatim_url).host
      @error = "Error contacting #{host}: #{e}"
      render :action => "error"
    end
  end
end
