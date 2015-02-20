class Tracetag < ActiveRecord::Base
  self.table_name = "gpx_file_tags"

  validates_format_of :tag, :with => /\A[^\/;.,?]*\z/
  validates_length_of :tag, :within => 1..255

  belongs_to :trace, :foreign_key => "gpx_id"
end
