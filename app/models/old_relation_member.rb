class OldRelationMember < ActiveRecord::Base
  belongs_to :user

  set_table_name 'relation_members'

end
