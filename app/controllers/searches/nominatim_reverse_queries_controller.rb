module Searches
  class NominatimReverseQueriesController < QueriesController
    include NominatimMethods

    LANGUAGE_CODES = { "cn" => "zh-Hans", "hk" => "zh-HK", "jp" => "ja", "tw" => "zh-Hant" }.freeze

    def create
      # get query parameters
      zoom = params[:zoom]

      # create result array
      @results = []

      # ask nominatim
      response = fetch_xml(nominatim_reverse_query_url(:format => "xml"))

      # add lang attribute for frontend in certain regions
      addressparts = response.elements["reversegeocode/addressparts"]
      lang = nil
      if addressparts
        region_code = addressparts.elements["ISO3166-2-lvl3"]&.text == "CN-HK" ? "hk" : addressparts.elements["country_code"]&.text
        lang = region_code ? LANGUAGE_CODES[region_code] : nil
      end

      # parse the response
      response.elements.each("reversegeocode/result") do |result|
        lat = result.attributes["lat"]
        lon = result.attributes["lon"]
        object_type = result.attributes["osm_type"]
        object_id = result.attributes["osm_id"]
        description = result.text

        @results.push(:lat => lat, :lon => lon,
                      :lang => lang,
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
