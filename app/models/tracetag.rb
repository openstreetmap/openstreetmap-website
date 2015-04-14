class Tracetag < ActiveRecord::Base
  self.table_name = "gpx_file_tags"

  belongs_to :trace, :foreign_key => "gpx_id"

  validates :trace, :associated => true
  validates :tag, :length => 1..255, :format => %r{\A[^/;.,?]*\z}
end
