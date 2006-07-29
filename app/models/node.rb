class Node < ActiveRecord::Base
  set_table_name 'current_nodes'
  belongs_to :user
end
