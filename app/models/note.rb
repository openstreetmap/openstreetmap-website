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
#  author_id  :bigint(8)
#  author_ip  :inet
#  body       :text
#
# Indexes
#
#  notes_created_at_idx   (created_at)
#  notes_tile_status_idx  (tile,status)
#  notes_updated_at_idx   (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#

class Note < ApplicationRecord
  include GeoRecord

  belongs_to :author, :class_name => "User", :optional => true
  has_many :comments, -> { left_joins(:author).where(:visible => true, :users => { :status => [nil, "active", "confirmed"] }).order(:created_at) }, :class_name => "NoteComment", :foreign_key => :note_id
  has_many :all_comments, -> { left_joins(:author).order(:created_at) }, :class_name => "NoteComment", :foreign_key => :note_id, :inverse_of => :note

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :only_integer => true }
  validates :author, :associated => true
  validates :body, :length => { :maximum => 2000 }, :characters => true
  validates :latitude, :longitude, :numericality => { :only_integer => true }
  validates :closed_at, :presence => true, :if => proc { :status == "closed" }
  validates :status, :inclusion => %w[open closed hidden]

  validate :validate_position

  scope :visible, -> { where.not(:status => "hidden") }
  scope :invisible, -> { where(:status => "hidden") }

  after_initialize :set_defaults

  DEFAULT_FRESHLY_CLOSED_LIMIT = 7.days

  def comments_with_extra_open_comment
    @comments_with_extra_open_comment ||= build_comments_with_extra_open_comment
  end

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

  # FIXME: notes_refactoring remove this once the backfilling is completed
  def body_migrated?
    attributes["body"].present?
  end

  # FIXME: notes_refactoring remove this once the backfilling is completed
  def author
    super || opened_note_comment&.author
  end

  # FIXME: notes_refactoring remove this once the backfilling is completed
  def author_ip
    super || opened_note_comment&.author_ip
  end

  # Return the note body
  def body
    body = super || opened_note_comment&.body&.to_s
    RichText.new("text", body)
  end

  private

  # FIXME: notes_refactoring remove this once the backfilling is completed
  def opened_note_comment
    comments.find_by(:event => "opened")
  end

  # NB: For API backwards compatibility the comments are prepended with an
  # `open`-comment that was persisted but is not anymore.
  def build_comments_with_extra_open_comment
    # FIXME: notes_refactoring remove this guard once the backfilling is completed
    return comments unless body_migrated?

    comments.to_a.unshift(NoteComment.new(
                            :created_at => created_at,
                            :event => "opened",
                            :note => self,
                            :author => author,
                            :author_ip => author_ip,
                            :body => body
                          ))
  end

  # Fill in default values for new notes
  def set_defaults
    self.status = "open" unless attribute_present?(:status)
  end
end
