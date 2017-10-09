require "migrate"

class AddEndTimeToChangesets < ActiveRecord::Migration[5.0]
  def self.up
    # swap the boolean closed-or-not for a time when the changeset will
    # close or has closed.
    add_column(:changesets, :closed_at, :datetime, :null => false)

    # it appears that execute will only accept string arguments, so
    # this is an ugly, ugly hack to get some sort of mysql/postgres
    # independence. now i have to go wash my brain with bleach.
    execute("update changesets set closed_at=(now()-'1 hour'::interval) where open=(1=0)")
    execute("update changesets set closed_at=(now()+'1 hour'::interval) where open=(1=1)")

    # remove the open column as it is unnecessary now and denormalises
    # the table.
    remove_column :changesets, :open

    # add a column to keep track of the number of changes in a changeset.
    # could probably work out how many changes there are here, but i'm not
    # sure its actually important.
    add_column(:changesets, :num_changes, :integer,
               :null => false, :default => 0)
  end

  def self.down
    # in the reverse direction, we can look at the closed_at to figure out
    # if changesets are closed or not.
    add_column(:changesets, :open, :boolean, :null => false, :default => true)
    execute("update changesets set open=(closed_at > now())")
    remove_column :changesets, :closed_at

    # remove the column for tracking number of changes
    remove_column :changesets, :num_changes
  end
end
