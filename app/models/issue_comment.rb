# == Schema Information
#
# Table name: issue_comments
#
#  id         :integer          not null, primary key
#  issue_id   :integer          not null
#  user_id    :integer          not null
#  body       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_issue_comments_on_issue_id  (issue_id)
#  index_issue_comments_on_user_id   (user_id)
#
# Foreign Keys
#
#  issue_comments_issue_id_fkey  (issue_id => issues.id) ON DELETE => cascade
#  issue_comments_user_id        (user_id => users.id) ON DELETE => cascade
#

class IssueComment < ActiveRecord::Base
  belongs_to :issue
  belongs_to :user

  validates :body, :presence => true
  validates :user, :presence => true
  validates :issue, :presence => true
end
