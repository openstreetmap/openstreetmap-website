
# require 'sprockets/railtie'

class Communities

  # include Sprockets::Helpers::RailsHelper

  def self.local_chapters
    self.load_local_chapters
  end

  protected

  def self.load_local_chapters
    puts Dir.pwd
    json_file = File.expand_path("node_modules/osm-community-index/dist/completeFeatureCollection.json", Dir.pwd);
    # json_file = File.expand_path("./node_modules/osm-community-index", Dir.pwd);

    path = File.exist?(json_file) # Dir.pwd # File.open(json_file, "r")
    community_index = JSON.parse(File.read(json_file))

    array_of_entries = []
    community_index['features'].each do |feature|
      feature['properties']['resources'].each do |id, data|
        data.each do |key, value|
          if key == "type" and value == "osm-lc" and data['strings']['community']
            array_of_entries.push({ id: id, name: data['strings']['community'], url: data['strings']['url'] });
          end
        end
      end
    end

    return array_of_entries
  end

end
