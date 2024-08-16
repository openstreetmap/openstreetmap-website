# == Schema Information
#
# Table name: communities
#
#  id          :bigint(8)        not null, primary key
#  name        :string           not null
#  description :text             not null
#  leader_id   :bigint(8)        not null
#  slug        :string           not null
#  location    :string           not null
#  latitude    :float            not null
#  longitude   :float            not null
#  min_lat     :float            not null
#  max_lat     :float            not null
#  min_lon     :float            not null
#  max_lon     :float            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_communities_on_leader_id  (leader_id)
#  index_communities_on_slug       (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (leader_id => users.id)
#

# At this time a community has one leader.  The leader of a community starts out
# being the user that created the community.  The creator of a community also
# is an organizer member.

class Community < ApplicationRecord
  extend FriendlyId
  friendly_id :name, :use => :slugged

  # Organizers before members, a tad hacky, but works for now.
  has_many :community_members, -> { order(:user_id) }, :inverse_of => :community
  has_many :users, :through => :community_members # TODO: counter_cache

  belongs_to :leader, :class_name => "User"
  has_many :community_links
  has_many :events, -> { order(:moment) }, :inverse_of => :community

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

  def member?(user)
    community_members.where(:user_id => user.id).count.positive?
  end

  def members
    community_members.where(:role => CommunityMember::Roles::MEMBER)
  end

  def organizer?(user)
    community_members.where(:user_id => user.id, :role => CommunityMember::Roles::ORGANIZER).count.positive?
  end

  def organizers
    community_members.where(:role => CommunityMember::Roles::ORGANIZER)
  end

  def bbox
    BoundingBox.new(min_lon, min_lat, max_lon, max_lat)
  end
end
