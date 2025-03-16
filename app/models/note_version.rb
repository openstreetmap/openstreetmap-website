# == Schema Information
#
# Table name: note_versions
#
#  note_id              :bigint           not null, primary key
#  latitude             :integer          not null
#  longitude            :integer          not null
#  tile                 :bigint           not null
#  timestamp            :datetime         not null
#  status               :enum             not null
#  event                :enum             not null
#  description          :text             not null
#  user_id              :bigint
#  user_ip              :inet
#  version              :bigint           not null, primary key
#  redaction_id         :integer
#  note_comment_id      :bigint           not null
#  note_comment_visible :boolean          default(TRUE), not null
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
end
