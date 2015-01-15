require 'csv'
require 'algoliasearch'

FILENAME       = 'World_Cities_Location.csv'
APPLICATION_ID = "getYourOwn ;)"
API_KEY        = "getYourOwn ;)"

def import(filename, applicationId, apiKey )
  Algolia.init :application_id => applicationId, :api_key => apiKey
  cities = CSV.read(filename).map { |datapoint| { :country => datapoint[1],
                                                  :city => datapoint[2],
                                                  :_geoloc => {
                                                    :lat => datapoint[3].to_f,
                                                    :lng => datapoint[4].to_f
                                                  }} }
  index = Algolia::Index.new("worldCities")
  cities.each_slice(1000) do |batch|
    index.add_objects(batch)
    puts(batch)
  end
end

import( FILENAME, APPLICATION_ID, API_KEY)
