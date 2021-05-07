# == Schema Information
#
# Table name: events
#
#  id           :bigint(8)        not null, primary key
#  title        :string           not null
#  moment       :datetime
#  location     :string
#  location_url :string
#  latitude     :float
#  longitude    :float
#  description  :text
#  microcosm_id :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Event < ApplicationRecord
  belongs_to :microcosm
  has_many :event_attendances
  has_many :event_organizers

  scope :future, -> { where("moment >= ?", Time.now) }
  scope :past, -> { where("moment < ?", Time.now) }

  has_many :yes_attandances, -> { where :intention => EventAttendance::Intentions::YES }, :class_name => "EventAttendance"
  has_many :yes_attendees, :through => :yes_attandances, :source => :user

  validates :moment, :datetime_format => true
  validates :location, :length => 1..255, :characters => true, :if => :location?
  validates :location_url, :length => 1..255, :if => :location_url?
  validates :location_url, :url => { :allow_blank => false }, :if => :location_url?
  validates :latitude, :numericality => true, :allow_nil => true, :inclusion => { :in => -90..90 }
  validates :longitude, :numericality => true, :allow_nil => true, :inclusion => { :in => -180..180 }
  validates :microcosm, :presence => true

  def location?
    !location.nil?
  end

  def location_url?
    !location_url.nil?
  end

  def attendees(intention)
    EventAttendance.where(:event_id => id, :intention => intention)
  end

  def yes_attendees
    attendees(EventAttendance::Intentions::YES)
  end

  def no_attendees
    attendees(EventAttendance::Intentions::NO)
  end

  def maybe_attendees
    attendees(EventAttendance::Intentions::MAYBE)
  end

  def organizers
    EventOrganizer.where(:event_id => id)
  end

  def past?
    moment < Time.now
  end
end
