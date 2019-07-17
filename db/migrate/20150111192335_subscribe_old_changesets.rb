class SubscribeOldChangesets < ActiveRecord::Migration[4.2]
  class Changeset < ActiveRecord::Base
  end

  def up
    Changeset.find_each do |changeset|
      changeset.subscribers << changeset.user unless changeset.subscribers.exists?(changeset.user.id)
    end
  end

  def down; end
end
