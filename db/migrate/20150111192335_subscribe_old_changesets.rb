class SubscribeOldChangesets < ActiveRecord::Migration[5.0]
  def up
    Changeset.find_each do |changeset|
      changeset.subscribers << changeset.user unless changeset.subscribers.exists?(changeset.user.id)
    end
  end

  def down; end
end
