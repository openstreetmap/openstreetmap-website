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

  attr_accessible :lat, :lon

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

  # Return a flattened version of the comments for a note
  def flatten_comment(separator_char, upto_timestamp = :nil)
    resp = ""
    comment_no = 1
    self.comments.each do |comment|
      next if upto_timestamp != :nil and comment.created_at > upto_timestamp
      resp += (comment_no == 1 ? "" : separator_char)
      resp += comment.body if comment.body
      resp += " [ " 
      resp += comment.author.display_name if comment.author
      resp += " " + comment.created_at.to_s + " ]"
      comment_no += 1
    end

    return resp
  end

  # Check if a note is visible
  def visible?
    return status != "hidden"
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
