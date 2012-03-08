class ChangesetTag < ActiveRecord::Base
  self.primary_keys = "changeset_id", "k"

  belongs_to :changeset

  validates_presence_of :changeset
  validates_length_of :k, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :k, :scope => :changeset_id
  validates_length_of :v, :maximum => 255, :allow_blank => true
end
