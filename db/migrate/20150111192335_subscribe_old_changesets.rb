class SubscribeOldChangesets < ActiveRecord::Migration
  def up
    Changeset.find_each do |changeset|
      changeset.subscribers << changeset.user unless changeset.subscribers.exists?(changeset.user)
    end
  end

  def down
  end
end
