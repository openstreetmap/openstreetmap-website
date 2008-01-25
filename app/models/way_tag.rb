class WayTag < ActiveRecord::Base
  set_table_name 'current_way_tags'

  # False multipart keys. The following would be a hack:
  # set_primary_keys :id, :k, :v
  # FIXME add a real multipart key to waytags so that we can do eager loadin

  belongs_to :way, :foreign_key => 'id'
end
