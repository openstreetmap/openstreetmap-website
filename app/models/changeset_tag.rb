# == Schema Information
#
# Table name: changeset_tags
#
#  changeset_id :bigint           not null, primary key
#  k            :string           default(""), not null, primary key
#  v            :string           default(""), not null
#
# Foreign Keys
#
#  changeset_tags_id_fkey  (changeset_id => changesets.id)
#

class ChangesetTag < ApplicationRecord
  belongs_to :changeset

  validates :changeset, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }, :characters => true
  validates :k, :uniqueness => { :scope => :changeset_id }
end
