# == Schema Information
#
# Table name: note_tags
#
#  note_id :bigint(8)        not null, primary key
#  k       :string           default(""), not null, primary key
#  v       :string           default(""), not null
#
# Foreign Keys
#
#  note_tags_id_fkey  (note_id => notes.id)
#

class NoteTag < ApplicationRecord
  belongs_to :note

  validates :note, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }, :characters => true
  validates :k, :uniqueness => { :scope => :note_id }
end
