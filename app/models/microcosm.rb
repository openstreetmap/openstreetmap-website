# == Schema Information
#
# Table name: microcosms
#
#  id          :bigint(8)        not null, primary key
#  name        :string           not null
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  slug        :string           not null
#  location    :string           not null
#  latitude    :float            not null
#  longitude   :float            not null
#  min_lat     :float            not null
#  max_lat     :float            not null
#  min_lon     :float            not null
#  max_lon     :float            not null
#

class Microcosm < ApplicationRecord
  extend FriendlyId
  friendly_id :name, :use => :slugged
  self.ignored_columns = ["key"]

  has_many :microcosm_members
  has_many :users, :through => :microcosm_members # TODO: counter_cache
  has_many :microcosm_links
  has_many :events

  def set_link(site, url)
    link = MicrocosmLink.find_or_initialize_by(:microcosm_id => id, :site => site)
    link.url = url
    link.save!
  end

  def organizer?(user)
    microcosm_members.where(:user_id => user.id, :role => MicrocosmMember::Roles::ORGANIZER).count.positive?
  end

  def organizers
    microcosm_members.where(:role => MicrocosmMember::Roles::ORGANIZER)
  end

  # Override GeoRecord because we don't have a tile attribute.
  def update_tile; end

  def bbox
    BoundingBox.new(min_lon, min_lat, max_lon, max_lat)
  end
end
