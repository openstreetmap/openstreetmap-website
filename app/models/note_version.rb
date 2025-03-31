# == Schema Information
#
# Table name: note_versions
#
#  note_id         :bigint           not null, primary key
#  latitude        :integer          not null
#  longitude       :integer          not null
#  tile            :bigint           not null
#  timestamp       :datetime         not null
#  status          :enum             not null
#  event           :enum             not null
#  description     :text             not null
#  user_id         :bigint
#  user_ip         :inet
#  version         :bigint           not null, primary key
#  redaction_id    :integer
#  note_comment_id :bigint           not null
#
# Indexes
#
#  note_versions_note_comment_id_idx  (note_comment_id)
#
# Foreign Keys
#
#  note_versions_redaction_id_fkey  (redaction_id => redactions.id)
#

class NoteVersion < ApplicationRecord
  belongs_to :note, :class_name => "Note", :inverse_of => :note_versions

  has_many :note_tag_versions, :class_name => "NoteTagVersion", :foreign_key => [:note_id, :version], :inverse_of => :note_version

  def self.from_note(note, timestamp, note_author_info, note_comment_id, event)
    note_version = NoteVersion.new

    note_version.note_id = note.id
    note_version.latitude = note.latitude
    note_version.longitude = note.longitude
    note_version.tile = note.tile
    note_version.timestamp = timestamp
    note_version.status = note.status
    note_version.event = event
    note_version.description = note.description
    note_version.user_id = note_author_info[:user_id]
    note_version.user_ip = note_author_info[:user_ip]
    note_version.version = note.version
    note_version.note_comment_id = note_comment_id
    note_version.tags = note.tags

    note_version
  end

  def save_with_history!
    save!

    tags.each do |k, v|
      tag = NoteTagVersion.new
      tag.k = k
      tag.v = v
      tag.note_id = note_id
      tag.version = version
      tag.save!
    end
  end

  def tags
    @tags ||= note_tag_versions.to_h { |t| [t.k, t.v] }
  end

  attr_writer :tags
end
