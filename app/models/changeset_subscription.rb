# == Schema Information
#
# Table name: changesets_subscribers
#
#  subscriber_id :bigint           not null
#  changeset_id  :bigint           not null
#
# Indexes
#
#  index_changesets_subscribers_on_changeset_id                    (changeset_id)
#  index_changesets_subscribers_on_subscriber_id_and_changeset_id  (subscriber_id,changeset_id) UNIQUE
#
# Foreign Keys
#
#  changesets_subscribers_changeset_id_fkey   (changeset_id => changesets.id)
#  changesets_subscribers_subscriber_id_fkey  (subscriber_id => users.id)
#
class ChangesetSubscription < ApplicationRecord
  self.table_name = "changesets_subscribers"

  belongs_to :subscriber, :class_name => "User"
  belongs_to :changeset
end
