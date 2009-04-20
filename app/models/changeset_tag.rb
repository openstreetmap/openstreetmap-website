class ChangesetTag < ActiveRecord::Base
  belongs_to :changeset, :foreign_key => 'id'

  validates_presence_of :id
  validates_length_of :k, :v, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :id, :scope => :k
  validates_numericality_of :id, :only_integer => true
end
