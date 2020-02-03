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
#  latitude    :integer          not null
#  longitude   :integer          not null
#  min_lat     :integer          not null
#  max_lat     :integer          not null
#  min_lon     :integer          not null
#  max_lon     :integer          not null
#

# latitude and longitude are like nodes
# min_lat, max_lat, min_lon, and max_lon are like changesets

class Microcosm < ApplicationRecord
  include GeoRecord

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
  def update_tile end

  # Create min_lat=, max_lat=, min_lon=, max_lon= methods.
  [:min, :max].each do |extremum|
    [:lat, :lon].each do |coord|
      attr = "#{extremum}_#{coord}"
      # setter
      define_method "#{attr}=" do |val|
        self[attr] = (Float(val) * SCALE).round
      end
      # getter
      define_method attr do
        Coord.new(self[attr].to_f / SCALE)
      end
    end
  end
end
