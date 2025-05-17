# == Schema Information
#
# Table name: note_tag_versions
#
#  note_id :bigint           not null, primary key
#  version :bigint           default(1), not null, primary key
#  k       :string           not null, primary key
#  v       :string           not null
#
# Foreign Keys
#
#  note_tag_versions_id_fkey  ([note_id, version] => note_versions[note_id, version])
#

class NoteTagVersion < ApplicationRecord
  belongs_to :note_version, :foreign_key => [:note_id, :version], :inverse_of => :note_tag_versions

  validates :note_version, :associated => true
  validates :k, :v, :length => { :maximum => 255 }, :characters => true
  validates :k, :uniqueness => { :scope => [:note_id, :version] }
end
