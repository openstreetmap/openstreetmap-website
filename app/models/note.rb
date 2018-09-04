# == Schema Information
#
# Table name: notes
#
#  id         :integer          not null, primary key
#  latitude   :integer          not null
#  longitude  :integer          not null
#  tile       :integer          not null
#  updated_at :datetime         not null
#  created_at :datetime         not null
#  status     :enum             not null
#  closed_at  :datetime
#
# Indexes
#
#  notes_created_at_idx   (created_at)
#  notes_tile_status_idx  (tile,status)
#  notes_updated_at_idx   (updated_at)
#

class Note < ActiveRecord::Base
  include GeoRecord

  has_many :comments, -> { left_joins(:author).where(:visible => true, :users => { :status => [nil, "active", "confirmed"] }).order(:created_at) }, :class_name => "NoteComment", :foreign_key => :note_id

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :integer_only => true }
  validates :latitude, :longitude, :numericality => { :only_integer => true }
  validates :closed_at, :presence => true, :if => proc { :status == "closed" }
  validates :status, :inclusion => %w[open closed hidden]

  validate :validate_position

  scope :visible, -> { where.not(:status => "hidden") }
  scope :invisible, -> { where(:status => "hidden") }

  after_initialize :set_defaults

  # Sanity check the latitude and longitude and add an error if it's broken
  def validate_position
    errors.add(:base, "Note is not in the world") unless in_world?
  end

  # Close a note
  def close
    self.status = "closed"
    self.closed_at = Time.now.getutc
    save
  end

  # Reopen a note
  def reopen
    self.status = "open"
    self.closed_at = nil
    save
  end

  # Check if a note is visible
  def visible?
    status != "hidden"
  end

  # Check if a note is closed
  def closed?
    !closed_at.nil?
  end

  # Return the author object, derived from the first comment
  def author
    comments.first.author
  end

  # Return the author IP address, derived from the first comment
  def author_ip
    comments.first.author_ip
  end

  private

  # Fill in default values for new notes
  def set_defaults
    self.status = "open" unless attribute_present?(:status)
  end
end
