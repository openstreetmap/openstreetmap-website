class WayTag < ActiveRecord::Base
  set_table_name 'current_way_tags'

  # false multipart key
  set_primary_keys :id, :k, :v

  belongs_to :way, :foreign_key => 'id'
end
