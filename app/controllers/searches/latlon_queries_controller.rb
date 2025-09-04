# frozen_string_literal: true

module Searches
  class LatlonQueriesController < QueriesController
    def create
      lat = params[:lat].to_f
      lon = params[:lon].to_f

      if params[:latlon_digits]
        # We've got two nondescript numbers for a query, which can mean both "lat, lon" or "lon, lat".
        @results = []

        if lat.between?(-90, 90) && lon.between?(-180, 180)
          @results.push(:lat => params[:lat], :lon => params[:lon],
                        :zoom => params[:zoom],
                        :name => "#{params[:lat]}, #{params[:lon]}")
        end

        if lon.between?(-90, 90) && lat.between?(-180, 180)
          @results.push(:lat => params[:lon], :lon => params[:lat],
                        :zoom => params[:zoom],
                        :name => "#{params[:lon]}, #{params[:lat]}")
        end

        if @results.empty?
          @error = "Latitude or longitude are out of range"
          render :action => "error"
        end
      else
        # Coordinates in a query have come with markers for latitude and longitude.
        if !lat.between?(-90, 90)
          @error = "Latitude #{lat} out of range"
          render :action => "error"
        elsif !lon.between?(-180, 180)
          @error = "Longitude #{lon} out of range"
          render :action => "error"
        else
          @results = [{ :lat => params[:lat], :lon => params[:lon],
                        :zoom => params[:zoom],
                        :name => "#{params[:lat]}, #{params[:lon]}" }]
        end
      end
    end
  end
end
