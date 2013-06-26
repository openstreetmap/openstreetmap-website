class Note < ActiveRecord::Base
  include GeoRecord

  has_many :comments, :class_name => "NoteComment",
                      :foreign_key => :note_id,
                      :order => :created_at,
                      :conditions => { :visible => true }

  validates_presence_of :id, :on => :update
  validates_uniqueness_of :id
  validates_numericality_of :latitude, :only_integer => true
  validates_numericality_of :longitude, :only_integer => true
  validates_presence_of :closed_at if :status == "closed"
  validates_inclusion_of :status, :in => ["open", "closed", "hidden"]
  validate :validate_position

  after_initialize :set_defaults

  # Sanity check the latitude and longitude and add an error if it's broken
  def validate_position
    errors.add(:base, "Note is not in the world") unless in_world?
  end

  # Close a note
  def close
    self.status = "closed"
    self.closed_at = Time.now.getutc
    self.save
  end

  # Reopen a note
  def reopen
    self.status = "open"
    self.closed_at = nil
    self.save
  end

  # Check if a note is visible
  def visible?
    status != "hidden"
  end

  # Check if a note is closed
  def closed?
    not closed_at.nil?
  end

  # Return the author object, derived from the first comment
  def author
    self.comments.first.author
  end

  # Return the author IP address, derived from the first comment
  def author_ip
    self.comments.first.author_ip
  end

private

  # Fill in default values for new notes
  def set_defaults
    self.status = "open" unless self.attribute_present?(:status)
  end
end
