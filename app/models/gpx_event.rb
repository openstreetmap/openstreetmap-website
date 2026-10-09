# frozen_string_literal: true

# == Schema Information
#
# Table name: gpx_events
#
#  id         :bigint           not null, primary key
#  gpx_id     :bigint           not null
#  action     :enum             not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_gpx_events_on_created_at_and_id  (created_at,id)
#

# Log of traces added to or removed from the set that other services can use,
# so they can keep their own copy up to date. A trace is in the set while it
# is visible, imported and identifiable. There is no foreign key on gpx_id
# because the event must stay after the trace is removed.
class GpxEvent < ApplicationRecord
  ACTIONS = %w[added removed].freeze

  validates :gpx_id, :presence => true
  validates :action, :inclusion => ACTIONS
end
