class ChangesetTag < ActiveRecord::Base
  self.primary_keys = "changeset_id", "k"

  belongs_to :changeset

  validates :changeset, :presence => true, :associated => true
  validates :k, :v, :allow_blank => true, :length => { :maximum => 255 }
  validates :k, :uniqueness => { :scope => :changeset_id }
end
