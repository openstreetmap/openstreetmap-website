# frozen_string_literal: true

class SuspendSoftDeletedAccounts < ActiveRecord::Migration[8.1]
  def up
    User.where("status = 'deleted' AND display_name NOT LIKE 'user_%'").in_batches do |users|
      users.update_all(:status => :suspended)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
