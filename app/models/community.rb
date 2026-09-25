# frozen_string_literal: true

class Community < FrozenRecord::Base
  self.base_path = Rails.root.join("node_modules/osm-community-index/dist/json/")
  self.backend = OsmCommunityIndex::ResourceBackend

  def url
    strings["url"]
  end
end
