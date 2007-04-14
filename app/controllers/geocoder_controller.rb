class GeocoderController < ApplicationController
  layout 'site'

  require 'net/http'
  require 'rexml/document'

  before_filter :authorize_web
  before_filter :require_user

  def search
    res_hash = {}
    @postcode_arr = []
    @res_ary = []

    if params[:query][:postcode] != "" 
      postcode = params[:query][:postcode]
      if postcode.match(/(^\d{5}$)|(^\d{5}-\d{4}$)/)
        #its a zip code - do something
      else
        Net::HTTP.start('www.freethepostcode.org') do |http|
          resp = http.get("/geocode?postcode=#{postcode}")
          lat = resp.body.scan(/[4-6][0-9]\.?[0-9]+/)
          lon = resp.body.scan(/[-+][0-9]\.?[0-9]+/)
          @postcode_array = [lat, lon]
          redirect_to "/index.html?lat=#{@postcode_array[0]}&lon=#{@postcode_array[1]}&zoom=14"
        end
      end
    else
      if params[:query][:place_name] != nil or "" 
        place_name = params[:query][:place_name]
        Net::HTTP.start('ws.geonames.org') do |http|
          res = http.get("/search?q=#{place_name}&maxRows=10")
          xml = REXML::Document.new(res.body)
          xml.elements.each("geonames/geoname") do |ele|
            res_hash = {}
            ele.elements.each("name"){ |n| res_hash['name'] = n.text }
            ele.elements.each("countryCode"){ |n| res_hash['country_code'] = n.text }
            ele.elements.each("countryNode"){ |n| res_hash['country_name'] = n.text }
            ele.elements.each("lat"){ |n| res_hash['lat'] = n.text }
            ele.elements.each("lng"){ |n| res_hash['lon']= n.text }
            @res_ary << res_hash
          end 
        end
      end
      redirect_to :controller => 'geocoder', :action => 'results'
    end
  end

  def result

  end
end
