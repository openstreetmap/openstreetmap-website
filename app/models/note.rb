# == Schema Information
#
# Table name: notes
#
#  id         :bigint(8)        not null, primary key
#  latitude   :integer          not null
#  longitude  :integer          not null
#  tile       :bigint(8)        not null
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

class Note < ApplicationRecord
  include GeoRecord

  has_many :comments, -> { left_joins(:author).where(:visible => true, :users => { :status => [nil, "active", "confirmed"] }).order(:created_at) }, :class_name => "NoteComment", :foreign_key => :note_id
  has_many :all_comments, -> { left_joins(:author).order(:created_at) }, :class_name => "NoteComment", :foreign_key => :note_id, :inverse_of => :note

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :only_integer => true }
  validates :latitude, :longitude, :numericality => { :only_integer => true }
  validates :closed_at, :presence => true, :if => proc { :status == "closed" }
  validates :status, :inclusion => %w[open closed hidden]

  validate :validate_position

  scope :visible, -> { where.not(:status => "hidden") }
  scope :invisible, -> { where(:status => "hidden") }

  scope :filter_hidden_notes, lambda { |user|
    if user&.moderator?
      all
    else
      visible
    end
  }

  scope :filter_by_status, lambda { |status|
    case status
    when "open"
      where(:status => "open")
    when "closed"
      where(:status => "closed")
    else
      all
    end
  }

  scope :filter_by_note_type, lambda { |note_type, user_id|
    case note_type
    when "commented"
      joins(:comments)
        .where("notes.id IN (SELECT note_id FROM note_comments WHERE author_id != ?)", user_id)
        .distinct
    when "submitted"
      joins(:comments)
        .where(:note_comments => { :author_id => user_id })
        .where("note_comments.id = (SELECT MIN(id) FROM note_comments WHERE note_comments.note_id = notes.id)")
        .distinct
    else
      all
    end
  }

  scope :filter_by_date_range, lambda { |from, to|
    notes = all
    notes = notes.where(:notes => { :created_at => DateTime.parse(from).. }) if from.present?
    notes = notes.where(:notes => { :created_at => ..DateTime.parse(to) }) if to.present?
    notes
  }

  scope :sort_by_params, lambda { |sort_by, sort_order|
    sort_by ||= "updated_at"
    sort_order ||= "desc"
    order("#{sort_by} #{sort_order}")
  }

  after_initialize :set_defaults

  DEFAULT_FRESHLY_CLOSED_LIMIT = 7.days

  # Sanity check the latitude and longitude and add an error if it's broken
  def validate_position
    errors.add(:base, "Note is not in the world") unless in_world?
  end

  # Close a note
  def close
    self.status = "closed"
    self.closed_at = Time.now.utc
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

  def freshly_closed?
    return false unless closed?

    Time.now.utc < freshly_closed_until
  end

  def freshly_closed_until
    return nil unless closed?

    closed_at + DEFAULT_FRESHLY_CLOSED_LIMIT
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
