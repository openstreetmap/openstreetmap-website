class GeocoderController < ApplicationController

  require 'net/http'
  require 'rexml/document'

  def search
    @res_hash = {}
    @postcode_arr = []


    if params[:query][:place_name] != nil or "" 
      place_name = params[:query][:place_name]
      Net::HTTP.start('ws.geonames.org') do |http|
        res = http.get("/search?q=#{place_name}&maxRows=10")
        xml = REXML::Document.new(res.body)
        xml.elements.each("/geonames/geoname") do |ele|
          ele.elements.each("name"){ |n| @res_hash['name'] = n.text }
          ele.elements.each("countryCode"){ |n| @res_hash['country'] = n.text }
          ele.elements.each("lat"){ |n| @res_hash['lat'] = n.text }
          ele.elements.each("lng"){ |n| @res_hash['lon']= n.text }
        end
      end
    end
    
    if params[:query][:postcode]
      postcode = params[:query][:postcode]
      Net::HTTP.start('www.freethepostcode.org') do |http|
        unless resp.code ~ /^2*/
        resp = http.get("/geocode?postcode=#{postcode}")
        lat = resp.body.scan(/[4-6][0-9]\.?[0-9]+/)
        lon = resp.body.scan(/[-+][0-9]\.?[0-9]+/)
        @postcode_array = [lat, lon]
      else
      end
      redirect_to "/index.html?lat=#{@postcode_array[0]}&lon=#{@postcode_array[1]}&zoom=14"
    end
  end
end
