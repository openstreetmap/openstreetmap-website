class Trace < ActiveRecord::Base
  set_table_name 'gpx_files'

  has_many :old_nodes, :foreign_key => :id
  belongs_to :user

  def tags=(bleh)

  end
end
