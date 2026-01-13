# frozen_string_literal: true

# == Schema Information
#
# Table name: moderation_zones
#
#  id            :bigint           not null, primary key
#  name          :string           not null
#  reason        :string           not null
#  reason_format :enum             default("markdown")
#  zone          :st_polygon       not null, polygon, 4326
#  ends_at       :datetime
#  creator_id    :bigint           not null
#  revoker_id    :bigint
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_moderation_zones_on_creator_id  (creator_id)
#  index_moderation_zones_on_revoker_id  (revoker_id)
#
# Foreign Keys
#
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (revoker_id => users.id)
#
class ModerationZone < ApplicationRecord
  validates :name, :presence => true
  validates :reason, :presence => true
  validates :zone, :presence => true

  def self.falls_within_any?(lon:, lat:)
    factory = RGeo::Cartesian.simple_factory(:srid => 4326)
    point = factory.point(lon, lat)

    where(
      arel_table[:zone].st_contains(point)
    ).exists?
  end
end
