# == Schema Information
#
# Table name: composite_note_comments
#
#  id         :bigint
#  note_id    :bigint
#  visible    :boolean
#  created_at :datetime
#  author_ip  :inet
#  author_id  :bigint
#  body       :text
#  event      :enum
#

class CompositeNoteComment < ApplicationRecord
  belongs_to :note, :touch => true, :inverse_of => :composite_note_comments
  belongs_to :author, :class_name => "User", :optional => true

  def body
    RichText.new("text", self[:body])
  end
end
