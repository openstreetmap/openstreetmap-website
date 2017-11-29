# == Schema Information
#
# Table name: reports
#
#  id               :integer          not null, primary key
#  issue_id         :integer
#  reporter_user_id :integer
#  details          :text             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_reports_on_issue_id          (issue_id)
#  index_reports_on_reporter_user_id  (reporter_user_id)
#
# Foreign Keys
#
#  reports_issue_id_fkey          (issue_id => issues.id) ON DELETE => cascade
#  reports_reporter_user_id_fkey  (reporter_user_id => users.id) ON DELETE => cascade
#

class Report < ActiveRecord::Base
  belongs_to :issue, :counter_cache => true
  belongs_to :user, :class_name => "User", :foreign_key => :reporter_user_id

  validates :details, :presence => true
end
