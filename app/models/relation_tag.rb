class RelationTag < ActiveRecord::Base
  set_table_name 'current_relation_tags'

  belongs_to :relation, :foreign_key => 'id'

end
