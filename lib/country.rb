class Country
  attr_reader :code, :min_lat, :max_lat, :min_lon, :max_lon

  def initialize(code, min_lat, max_lat, min_lon, max_lon)
    @code = code
    @min_lat = min_lat
    @max_lat = max_lat
    @min_lon = min_lon
    @max_lon = max_lon
  end

  def self.find_by_code(code)
    countries[code]
  end

private

  def self.countries
    @@countries ||= load_countries
  end

  def self.load_countries
    countries = Hash.new
    xml = REXML::Document.new(File.read("config/countries.xml"))

    xml.elements.each("geonames/country") do |ele|
      code = ele.get_text("countryCode").to_s
      minlon = ele.get_text("west").to_s
      minlat = ele.get_text("south").to_s
      maxlon = ele.get_text("east").to_s
      maxlat = ele.get_text("north").to_s

      countries[code] = Country.new(code, minlat.to_f, maxlat.to_f, minlon.to_f, maxlon.to_f)
    end

    countries
  end
end
