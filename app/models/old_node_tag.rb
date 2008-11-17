class OldNodeTag < ActiveRecord::Base
  belongs_to :user

  set_table_name 'node_tags'

  validates_presence_of :id, :version
  validates_length_of :k, :v, :within => 0..255, :allow_blank => true

end
