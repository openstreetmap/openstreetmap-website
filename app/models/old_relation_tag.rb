class OldRelationTag < ActiveRecord::Base
  belongs_to :user

  set_table_name 'relation_tags'

end
