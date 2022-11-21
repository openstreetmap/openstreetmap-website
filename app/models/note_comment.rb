# == Schema Information
#
# Table name: note_comments
#
#  id         :bigint(8)        not null, primary key
#  note_id    :bigint(8)        not null
#  visible    :boolean          not null
#  created_at :datetime         not null
#  author_ip  :inet
#  author_id  :bigint(8)
#  body       :text
#  event      :enum
#
# Indexes
#
#  index_note_comments_on_body        (to_tsvector('english'::regconfig, body)) USING gin
#  index_note_comments_on_created_at  (created_at)
#  note_comments_note_id_idx          (note_id)
#
# Foreign Keys
#
#  note_comments_author_id_fkey  (author_id => users.id)
#  note_comments_note_id_fkey    (note_id => notes.id)
#

class NoteComment < ApplicationRecord
  belongs_to :note, :touch => true
  belongs_to :author, :class_name => "User", :optional => true

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :only_integer => true }
  validates :note, :associated => true
  validates :visible, :inclusion => [true, false]
  validates :author, :associated => true
  validates :event, :inclusion => %w[opened closed reopened commented hidden]
  validates :body, :length => { :maximum => 2000 }, :characters => true

  # Return the comment text
  def body
    RichText.new("text", self[:body])
  end
end
