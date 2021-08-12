
class Communities

  def self.local_chapters
    @local_chapters ||= self.load_local_chapters
  end

  protected

  def self.load_local_chapters

    json_file = File.expand_path("node_modules/osm-community-index/dist/completeFeatureCollection.json", Dir.pwd);
    community_index = JSON.parse(File.read(json_file))

    local_chapters = []
    community_index['features'].each do |feature|
      feature['properties']['resources'].each do |id, data|
        data.each do |key, value|
          if key == "type" and value == "osm-lc" and data['strings']['community']
            local_chapters.push({ id: id, name: data['strings']['community'], url: data['strings']['url'] });
          end
        end
      end
    end

    return local_chapters
  end

end
