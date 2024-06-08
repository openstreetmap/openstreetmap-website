# == Schema Information
#
# Table name: communities
#
#  id           :bigint(8)        not null, primary key
#  name         :string           not null
#  description  :text             not null
#  organizer_id :bigint(8)        not null
#  slug         :string           not null
#  location     :string           not null
#  latitude     :float            not null
#  longitude    :float            not null
#  min_lat      :float            not null
#  max_lat      :float            not null
#  min_lon      :float            not null
#  max_lon      :float            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_communities_on_organizer_id  (organizer_id)
#  index_communities_on_slug          (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organizer_id => users.id)
#

# At this time a community has one organizer.  The first organizer is
# the user that created the community.

class Community < ApplicationRecord
  extend FriendlyId
  friendly_id :name, :use => :slugged

  belongs_to :organizer, :class_name => "User"
  has_many :community_links

  validates :name, :presence => true, :length => 1..255, :characters => true
  validates :description, :presence => true, :length => 1..1023, :characters => true
  validates :location, :presence => true, :length => 1..255, :characters => true
  validates :latitude, :numericality => true, :inclusion => { :in => -90..90 }
  validates :longitude, :numericality => true, :inclusion => { :in => -180..180 }
  validates :min_lat, :numericality => true, :inclusion => { :in => -90.0..90.0 }
  validates :max_lat, :numericality => true, :inclusion => { :in => -90.0..90.0 }
  validates :min_lon, :numericality => true, :inclusion => { :in => -180.0..180.0 }
  validates :max_lon, :numericality => true, :inclusion => { :in => -180.0..180.0 }

  def longitude=(longitude)
    super(OSM.normalize_longitude(longitude))
  end

  def min_lon=(longitude)
    super(OSM.normalize_longitude(longitude))
  end

  def max_lon=(longitude)
    super(OSM.normalize_longitude(longitude))
  end

  def bbox
    BoundingBox.new(min_lon, min_lat, max_lon, max_lat)
  end
end
