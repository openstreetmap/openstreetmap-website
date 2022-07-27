# A backend for FrozenRecord

module OsmCommunityIndex
  module ResourceBackend
    def self.filename(_model)
      "resources.json"
    end

    def self.load(file_path)
      resources = JSON.parse(File.read(file_path))
      resources["resources"].values
    end
  end
end
