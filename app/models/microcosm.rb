# == Schema Information
#
# Table name: microcosms
#
#  id          :bigint(8)        not null, primary key
#  name        :string           not null
#  description :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  slug        :string
#  location    :string           not null
#  latitude    :float          not null
#  longitude   :float          not null
#  min_lat     :float          not null
#  max_lat     :float          not null
#  min_lon     :float          not null
#  max_lon     :float          not null
#

class Microcosm < ApplicationRecord
  extend FriendlyId
  friendly_id :name, :use => :slugged
  self.ignored_columns = ["key"]

  belongs_to :organizer, :class_name => "User"
  has_many :microcosm_links

  validates :name, :presence => true, :length => 1..255, :characters => true
  validates :description, :presence => true, :length => 1..1023, :characters => true
  validates :location, :presence => true, :length => 1..255, :characters => true
  validates :latitude, :numericality => true, :inclusion => { :in => -90..90 }
  validates :longitude, :numericality => true, :inclusion => { :in => -180..180 }
  validates :min_lat, :numericality => true, :inclusion => { :in => -90..90 }
  validates :max_lat, :numericality => true, :inclusion => { :in => -90..90 }
  validates :min_lon, :numericality => true, :inclusion => { :in => -180..180 }
  validates :max_lon, :numericality => true, :inclusion => { :in => -180..180 }

  def set_link(site, url)
    link = MicrocosmLink.find_or_initialize_by(:microcosm_id => id, :site => site)
    link.url = url
    link.save!
  end

  def bbox
    BoundingBox.new(min_lon, min_lat, max_lon, max_lat)
  end
end
