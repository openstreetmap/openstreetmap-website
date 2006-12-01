class Trace < ActiveRecord::Base
  set_table_name 'gpx_files'

  belongs_to :user

  def tags=(bleh)
  end

  def mime_type=(bleh)
  end
end
