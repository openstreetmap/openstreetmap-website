class Trace < ActiveRecord::Base
  set_table_name 'gpx_files'

  belongs_to :user
  has_many :tags, :class_name => 'Tracetag', :foreign_key => 'gpx_id'

  def tagstring=(s)
    self.tags = s.split().collect {|tag|
      tt = Tracetag.new
      tt.tag = tag
      tt
    }
  end
end
