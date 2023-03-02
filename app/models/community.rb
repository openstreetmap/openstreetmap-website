class Community < FrozenRecord::Base
  self.base_path = Rails.root.join("node_modules/osm-community-index/dist/")
  self.backend = OsmCommunityIndex::ResourceBackend

  def url
    strings["url"]
  end
end
