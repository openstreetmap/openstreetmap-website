class BackfillDeactivatesAtInUserBlocks < ActiveRecord::Migration[7.1]
  class UserBlock < ApplicationRecord; end

  disable_ddl_transaction!

  def up
    UserBlock.where(:needs_view => false, :deactivates_at => nil).in_batches do |relation|
      relation.update_all("deactivates_at = GREATEST(ends_at, updated_at)")
    end
  end
end
