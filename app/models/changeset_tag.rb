class ChangesetTag < ActiveRecord::Base

  belongs_to :changeset, :foreign_key => 'id'

end
