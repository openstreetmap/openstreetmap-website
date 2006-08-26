class OldWay < ActiveRecord::Base
  set_table_name 'ways'

  belongs_to :user

  def self.from_way(way)
    old_way = OldWay.new
    old_way.user_id = way.user_id
    old_way.timestamp = way.timestamp
    old_way.id = way.id
    return old_way
  end

end
