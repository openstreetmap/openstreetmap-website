class GeocoderController < ApplicationController
  layout 'site'

  require 'net/http'
  require 'rexml/document'

  def search
    res_hash = {}
    @postcode_arr = []
    @res_ary = []

    if params[:query][:postcode] 
      postcode = params[:query][:postcode]
      escaped_postcode = postcode.sub(/\s/,'%20')

      if postcode.match(/(^\d{5}$)|(^\d{5}-\d{4}$)/)
        # Its a zip code - ask geocoder.us
        # (They have a non commerical use api)
        Net::HTTP.start('rpc.geocoder.us') do |http|
          resp = http.get("/service/csv?zip=#{postcode}")
          data = resp.body.split(/, /) # lat,long,town,state,zip
          lat = data[0] 
          lon = data[1]
          redirect_to "/index.html?lat=#{lat}&lon=#{lon}&zoom=14"
        end
      elsif postcode.match(/^(\w{1,2}\d+\w?\s*\d\w\w)/)
        # It matched our naive UK postcode regexp
        # Ask npemap to do a combined npemap + freethepostcode search
        Net::HTTP.start('www.npemap.org.uk') do |http|
          resp = http.get("/cgi/geocoder.fcgi?format=text&postcode=#{escaped_postcode}")
          dataline = resp.body.split(/\n/)[1]
          data = dataline.split(/,/) # easting,northing,postcode,lat,long
          lat = data[3] 
          lon = data[4]
          redirect_to "/index.html?lat=#{lat}&lon=#{lon}&zoom=14"
        end
      else
        # Some other postcode / zip file
        redirect_to "/index.html?error=unknown_postcode_or_zip"
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
      redirect_to :controller => 'geocoder', :action => 'results', :params => @res_ary
    end
  end

  def result
    @res = :params[@res_ary]
  end
end
