# == Schema Information
#
# Table name: note_comments
#
#  id         :integer          not null, primary key
#  note_id    :integer          not null
#  visible    :boolean          not null
#  created_at :datetime         not null
#  author_ip  :inet
#  author_id  :integer
#  body       :text
#  event      :enum
#
# Indexes
#
#  index_note_comments_on_body        (to_tsvector('english'::regconfig, body))
#  index_note_comments_on_created_at  (created_at)
#  note_comments_note_id_idx          (note_id)
#
# Foreign Keys
#
#  note_comments_author_id_fkey  (author_id => users.id)
#  note_comments_note_id_fkey    (note_id => notes.id)
#

class NoteComment < ActiveRecord::Base
  belongs_to :note, :foreign_key => :note_id, :touch => true
  belongs_to :author, :class_name => "User", :foreign_key => :author_id

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :integer_only => true }
  validates :note, :presence => true, :associated => true
  validates :visible, :inclusion => [true, false]
  validates :author, :associated => true
  validates :event, :inclusion => %w[opened closed reopened commented hidden]
  validates :body, :format => /\A[^\x00-\x08\x0b-\x0c\x0e-\x1f\x7f\ufffe\uffff]*\z/

  # Return the comment text
  def body
    RichText.new("text", self[:body])
  end
end
