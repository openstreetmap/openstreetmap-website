class MapBugComment < ActiveRecord::Base
  set_table_name 'map_bug_comment'

  belongs_to :map_bug, :foreign_key => 'bug_id'
  belongs_to :user, :foreign_key => 'commenter_id'

  validates_inclusion_of :event, :in => [ "opened", "closed", "reopened", "commented", "hidden" ]
  validates_presence_of :id, :on => :update
  validates_uniqueness_of :id
  validates_presence_of :visible
  validates_presence_of :date_created
end
