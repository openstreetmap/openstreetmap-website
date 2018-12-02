# == Schema Information
#
# Table name: reports
#
#  id         :integer          not null, primary key
#  issue_id   :integer          not null
#  user_id    :integer          not null
#  details    :text             not null
#  category   :string           not null
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
#  reports_issue_id_fkey  (issue_id => issues.id)
#  reports_user_id_fkey   (user_id => users.id)
#

class Report < ActiveRecord::Base
  belongs_to :issue, :counter_cache => true
  belongs_to :user

  validates :issue, :presence => true
  validates :user, :presence => true
  validates :details, :presence => true, :characters => true
  validates :category, :presence => true

  def self.categories_for(reportable)
    case reportable.class.name
    when "DiaryEntry" then %w[spam offensive threat other]
    when "DiaryComment" then %w[spam offensive threat other]
    when "User" then %w[spam offensive threat vandal other]
    when "Note" then %w[spam personal abusive other]
    else %w[other]
    end
  end
end
