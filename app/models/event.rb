# == Schema Information
#
# Table name: events
#
#  id           :bigint(8)        not null, primary key
#  title        :string           not null
#  moment       :datetime         not null
#  location     :string           not null
#  location_url :string
#  latitude     :float
#  longitude    :float
#  description  :text             not null
#  community_id :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Event < ApplicationRecord
  belongs_to :community

  scope :future, -> { where("moment >= ?", Time.now.utc) }
  scope :past, -> { where("moment < ?", Time.now.utc) }

  validates :moment, :datetime_format => true
  validates :location, :length => { :maximum => 255 }, :presence => true
  # While latitude and longitude below will implicitly convert blanks to nil,
  # the string/url here will not and I don't know why.
  validates(
    :location_url,
    :allow_nil => true, :length => { :maximum => 255 },
    :url => { :allow_nil => true, :allow_blank => true, :schemes => ["https"] }
  )
  validates(
    :latitude,
    :allow_nil => true,
    :numericality => {
      :greater_than_or_equal_to => -90,
      :less_than_or_equal_to => 90
    }
  )
  validates(
    :longitude,
    :allow_nil => true,
    :numericality => {
      :greater_than_or_equal_to => -180,
      :less_than_or_equal_to => 180
    }
  )

  def past?
    moment < Time.now.utc
  end
end
