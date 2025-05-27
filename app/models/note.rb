# == Schema Information
#
# Table name: notes
#
#  id          :bigint           not null, primary key
#  latitude    :integer          not null
#  longitude   :integer          not null
#  tile        :bigint           not null
#  updated_at  :datetime         not null
#  created_at  :datetime         not null
#  status      :enum             not null
#  closed_at   :datetime
#  description :text             default(""), not null
#  user_id     :bigint
#  user_ip     :inet
#  version     :bigint           default(1), not null
#
# Indexes
#
#  index_notes_on_description             (to_tsvector('english'::regconfig, description)) USING gin
#  index_notes_on_user_id_and_created_at  (user_id,created_at) WHERE (user_id IS NOT NULL)
#  notes_created_at_idx                   (created_at)
#  notes_tile_status_idx                  (tile,status)
#  notes_updated_at_idx                   (updated_at)
#
# Foreign Keys
#
#  notes_user_id_fkey  (user_id => users.id)
#

class Note < ApplicationRecord
  include GeoRecord

  belongs_to :author, :class_name => "User", :foreign_key => "user_id", :optional => true

  has_many :comments, -> { left_joins(:author).where(:visible => true, :users => { :status => [nil, "active", "confirmed"] }).order(:created_at) }, :class_name => "CompositeNoteComment", :foreign_key => :note_id
  has_many :all_comments, -> { left_joins(:author).order(:created_at) }, :class_name => "CompositeNoteComment", :foreign_key => :note_id, :inverse_of => :note
  has_many :subscriptions, :class_name => "NoteSubscription"
  has_many :subscribers, :through => :subscriptions, :source => :user
  has_many :note_versions, -> { order(:version) }, :inverse_of => :note
  has_many :composite_note_comments, -> { order(:comment_id) }, :inverse_of => :note
  has_many :note_tags

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :only_integer => true }
  validates :latitude, :longitude, :numericality => { :only_integer => true }
  validates :closed_at, :presence => true, :if => proc { :status == "closed" }
  validates :status, :inclusion => %w[open closed hidden]

  validate :validate_position

  scope :visible, -> { where.not(:status => "hidden") }
  scope :invisible, -> { where(:status => "hidden") }

  after_initialize :set_defaults

  DEFAULT_FRESHLY_CLOSED_LIMIT = 7.days

  # Sanity check the latitude and longitude and add an error if it's broken
  def validate_position
    errors.add(:base, "Note is not in the world") unless in_world?
  end

  # Creates note from hash-table
  def self.from_params(params, note_author_info)
    note = Note.new

    # Check the arguments are sane
    raise OSM::APIBadUserInput, "No lat was given" unless params[:lat]
    raise OSM::APIBadUserInput, "No lon was given" unless params[:lon]
    raise OSM::APIBadUserInput, "No text was given" if params[:text].blank?

    # Extract the arguments
    lon = OSM.parse_float(params[:lon], OSM::APIBadUserInput, "lon was not a number")
    lat = OSM.parse_float(params[:lat], OSM::APIBadUserInput, "lat was not a number")
    description = params[:text]

    # Initialize the note (version is set to 1 by default)
    note.lat = lat
    note.lon = lon
    note.description = description
    raise OSM::APIBadUserInput, "The note is outside this world" unless note.in_world?

    # Saves note's author info
    note.user_id = note_author_info[:user_id]
    note.user_ip = note_author_info[:user_ip]

    # Extract the tags, if present
    note.tags = {}
    if params[:tags].present?
      parsed_tags = JSON.parse(params[:tags])
      parsed_tags.each do |key, value|
        note.tags[key] = value if key.presence && value.presence
      end
    end

    note
  end

  # Updates note from hash-table
  def update_from_params(params, note_author_info)
    # Update the note from passed parameters
    self.lon = OSM.parse_float(params[:lon], OSM::APIBadUserInput, "lon was not a number") if params[:lon].present?
    self.lat = OSM.parse_float(params[:lat], OSM::APIBadUserInput, "lat was not a number") if params[:lat].present?
    self.description = params[:text] if params[:text].present?

    # New note version will have current author info
    self.user_id = note_author_info[:user_id]
    self.user_ip = note_author_info[:user_ip]

    # Extract the tags, if present
    if params[:tags].present?
      self.tags = {}
      parsed_tags = JSON.parse(params[:tags])
      parsed_tags.each do |key, value|
        tags[key] = value if key.presence && value.presence
      end
    end

    # Increment version
    self.version = version + 1
  end

  # Saves created note without the history
  def save_without_history!
    # Saves current note to database
    save!

    # Create note tags
    tags = self.tags
    NoteTag.where(:note_id => id).delete_all
    tags.each do |k, v|
      tag = NoteTag.new
      tag.note_id = id
      tag.k = k
      tag.v = v
      tag.save!
    end
  end

  # Saves note's history
  def save_history!(timestamp, note_author_info, note_comment_id, event)
    # Creates and initializes note version
    note_version = NoteVersion.from_note(self, timestamp, note_author_info, note_comment_id, event)

    # Saves note version to database
    note_version.save_with_history!
  end

  # Close a note
  def close
    self.status = "closed"
    self.closed_at = Time.now.utc
    self.version = version + 1
  end

  # Hide a note
  def hide
    self.status = "hidden"
    self.version = version + 1
  end

  # Reopen a note
  def reopen
    self.status = "open"
    self.closed_at = nil
    self.version = version + 1
  end

  # Check if a note is visible
  def visible?
    status != "hidden"
  end

  # Check if a note is closed
  def closed?
    !closed_at.nil?
  end

  def freshly_closed?
    return false unless closed?

    Time.now.utc < freshly_closed_until
  end

  def freshly_closed_until
    return nil unless closed?

    closed_at + DEFAULT_FRESHLY_CLOSED_LIMIT
  end

  def tags
    @tags ||= note_tags.to_h { |t| [t.k, t.v] }
  end

  attr_writer :tags

  # Return the note's description
  def description
    RichText.new("text", super)
  end

  private

  # Fill in default values for new notes
  def set_defaults
    self.status = "open" unless attribute_present?(:status)
  end
end
