# == Schema Information
#
# Table name: reports
#
#  id         :integer          not null, primary key
#  issue_id   :integer
#  user_id    :integer
#  details    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_reports_on_issue_id  (issue_id)
#  index_reports_on_user_id   (user_id)
#
# Foreign Keys
#
#  reports_issue_id_fkey  (issue_id => issues.id) ON DELETE => cascade
#  reports_user_id_fkey   (user_id => users.id) ON DELETE => cascade
#

class Report < ActiveRecord::Base
  belongs_to :issue, :counter_cache => true
  belongs_to :user

  validates :details, :presence => true
end
