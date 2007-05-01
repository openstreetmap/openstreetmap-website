class GeocoderController < ApplicationController
  layout 'site'

  require 'net/http'
  require 'rexml/document'

  def search

    if params[:postcode]
      unless params[:postcode].empty?
        postcode = params[:postcode]
        check_postcode(postcode)
        return
      end
    end
    if params[:query][:postcode]
      unless params[:query][:postcode].empty?
        postcode =params[:query][:postcode]
        check_postcode(postcode)
        return
      end
    end
    if params[:query][:place_name]  
      @place_name = params[:query][:place_name]
      redirect_to :controller => 'geocoder', :action => 'results', :params => {:place_name => @place_name}
    end 
  end

  def check_postcode(p)

    @postcode_arr = []
    postcode = p.upcase
    escaped_postcode = postcode.sub(/\s/,'%20')

    begin
      if postcode.match(/(^\d{5}$)|(^\d{5}-\d{4}$)/)
        # Its a zip code - ask geocoder.us
        # (They have a non commerical use api)
        Net::HTTP.start('rpc.geocoder.us') do |http|
          resp = http.get("/service/csv?zip=#{postcode}")
          if resp.body.match(/couldn't find this zip/)
            redirect_to "/index.html?error=invalid_zip_code"
            return
          end
          data = resp.body.split(/, /) # lat,long,town,state,zip
          lat = data[0] 
          lon = data[1]
          redirect_to "/index.html?mlat=#{lat}&mlon=#{lon}&zoom=14"
          return
        end
      elsif postcode.match(/^([A-Z]{1,2}\d+[A-Z]?\s*\d[A-Z]{2})/)
        # It matched our naive UK postcode regexp
        # Ask npemap to do a combined npemap + freethepostcode search
        Net::HTTP.start('www.npemap.org.uk') do |http|
          resp = http.get("/cgi/geocoder.fcgi?format=text&postcode=#{escaped_postcode}")
          dataline = resp.body.split(/\n/)[1]
          data = dataline.split(/,/) # easting,northing,postcode,lat,long
          lat = data[3] 
          lon = data[4]
          redirect_to "/index.html?mlat=#{lat}&mlon=#{lon}&zoom=14"
          return
        end
      elsif postcode.match(/^[A-Z]\d[A-Z]\s*\d[A-Z]\d/)
        # It's a canadian postcode
        # Ask geocoder.ca (note - they have a per-day limit)
        postcode = postcode.sub(/\s/,'')
        Net::HTTP.start('geocoder.ca') do |http|
          resp = http.get("?geoit=XML&postal=#{postcode}")
          data_lat = resp.body.slice(/latt>.*?</)
          data_lon = resp.body.slice(/longt>.*?</)
          lat = data_lat.split(/[<>]/)[1]
          lon = data_lon.split(/[<>]/)[1]
          redirect_to "/index.html?mlat=#{lat}&mlon=#{lon}&zoom=14"
          return
        end
      elsif postcode.match(/(GIR 0AA|[A-PR-UWYZ]([0-9]{1,2}|([A-HK-Y][0-9]|[A-HK-Y][0-9]([0-9]|[ABEHMNPRV-Y]))|[0-9][A-HJKS-UW]) [0-9][ABD-HJLNP-UW-Z]{2})
        /)
        #its a UK postcode
        begin
          Net::HTTP.start('www.freethepostcode.org') do |http|
            resp = http.get("/geocode?postcode=#{postcode}")
            lat = resp.body.scan(/[4-6][0-9]\.?[0-9]+/)
            lon = resp.body.scan(/[-+][0-9]\.?[0-9]+/)
            redirect_to "/index.html?mlat=#{lat}&mlon=#{lon}&zoom=14"
            return
          end
        rescue
          redirect_to "/index.html"
          #redirect to somewhere else
        end
        redirect_to "/index.html?mlat=#{lat}&mlon=#{lon}&zoom=14"
        #redirect_to "/index.html?error=unknown_postcode_or_zip"
      elsif
        # Some other postcode / zip code
        # Throw it at geonames, and see if they have any luck with it
        Net::HTTP.start('ws.geonames.org') do |http|
          resp = http.get("/postalCodeSearch?postalcode=#{escaped_postcode}&maxRows=1")
          hits = resp.body.slice(/totalResultsCount>.*?</).split(/[<>]/)[1]
          if hits == "0"
            # Geonames doesn't know, it's probably wrong
            redirect_to "/index.html?error=unknown_postcode_or_zip"
            return
          end
          data_lat = resp.body.slice(/lat>.*?</)
          data_lon = resp.body.slice(/lng>.*?</)
          lat = data_lat.split(/[<>]/)[1]
          lon = data_lon.split(/[<>]/)[1]
          redirect_to "/index.html?mlat=#{lat}&mlon=#{lon}&zoom=14"
        end
      else
        # Some other postcode / zip file
        redirect_to "/index.html?error=unknown_postcode_or_zip"
        return
      end
    rescue
      #Its likely that an api is down
      redirect_to "/index.html?error=api_dpwn"
    end
  end

  def results
    @place_name = params[:place_name]
    res_hash = {}
    @res_ary = []
    begin
      Net::HTTP.start('ws.geonames.org') do |http|
        res = http.get("/search?q=#{@place_name}&maxRows=10")
        xml = REXML::Document.new(res.body)
        xml.elements.each("geonames/geoname") do |ele|
          res_hash = {}
          ele.elements.each("name"){ |n| res_hash['name'] = n.text }
          ele.elements.each("countryCode"){ |n| res_hash['countrycode'] = n.text }
          ele.elements.each("countryName"){ |n| res_hash['countryname'] = n.text }
          ele.elements.each("lat"){ |n| res_hash['lat'] = n.text }
          ele.elements.each("lng"){ |n| res_hash['lon']= n.text }
          @res_ary << res_hash
        end 
      end
    rescue
      #Flash a notice to say that geonames is broken
      redirect_to "/index.html"
    end
  end
end
