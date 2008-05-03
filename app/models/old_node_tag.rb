class OldNodeTag < ActiveRecord::Base
  belongs_to :user

  set_table_name 'node_tags'


end
