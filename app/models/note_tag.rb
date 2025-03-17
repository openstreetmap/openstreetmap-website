# == Schema Information
#
# Table name: note_tags
#
#  note_id :bigint           not null, primary key
#  k       :string           not null, primary key
#  v       :string           not null
#
# Foreign Keys
#
#  note_tags_id_fkey  (note_id => notes.id)
#

class NoteTag < ApplicationRecord
  belongs_to :note

  validates :note, :associated => true
  validates :k, :v, :length => { :maximum => 255 }, :characters => true
  validates :k, :uniqueness => { :scope => :note_id }
end
