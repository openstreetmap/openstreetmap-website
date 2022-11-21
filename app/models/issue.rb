# == Schema Information
#
# Table name: issues
#
#  id               :integer          not null, primary key
#  reportable_type  :string           not null
#  reportable_id    :integer          not null
#  reported_user_id :integer
#  status           :enum             default("open"), not null
#  assigned_role    :enum             not null
#  resolved_at      :datetime
#  resolved_by      :integer
#  updated_by       :integer
#  reports_count    :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_issues_on_assigned_role                      (assigned_role)
#  index_issues_on_reportable_type_and_reportable_id  (reportable_type,reportable_id)
#  index_issues_on_reported_user_id                   (reported_user_id)
#  index_issues_on_status                             (status)
#  index_issues_on_updated_by                         (updated_by)
#
# Foreign Keys
#
#  issues_reported_user_id_fkey  (reported_user_id => users.id)
#  issues_resolved_by_fkey       (resolved_by => users.id)
#  issues_updated_by_fkey        (updated_by => users.id)
#

class Issue < ApplicationRecord
  belongs_to :reportable, :polymorphic => true
  belongs_to :reported_user, :class_name => "User", :optional => true
  belongs_to :user_resolved, :class_name => "User", :foreign_key => :resolved_by, :optional => true
  belongs_to :user_updated, :class_name => "User", :foreign_key => :updated_by, :optional => true

  has_many :reports, :dependent => :destroy
  has_many :comments, :class_name => "IssueComment", :dependent => :destroy

  validates :reportable_id, :uniqueness => { :scope => [:reportable_type] }

  ASSIGNED_ROLES = %w[administrator moderator].freeze
  validates :assigned_role, :presence => true, :inclusion => ASSIGNED_ROLES

  before_validation :set_reported_user

  scope :with_status, ->(issue_status) { where(:status => issue_status) }
  scope :visible_to, ->(user) { where(:assigned_role => user.roles.map(&:role)) }

  def read_reports
    resolved_at.present? ? reports.where("updated_at < ?", resolved_at) : nil
  end

  def unread_reports
    resolved_at.present? ? reports.where("updated_at >= ?", resolved_at) : reports
  end

  include AASM
  aasm :column => :status, :no_direct_assignment => true do
    state :open, :initial => true
    state :ignored
    state :resolved

    event :ignore do
      transitions :from => :open, :to => :ignored
    end

    event :resolve do
      transitions :from => :open, :to => :resolved
      after do
        self.resolved_at = Time.now.utc
      end
    end

    event :reopen do
      transitions :from => :resolved, :to => :open
      transitions :from => :ignored, :to => :open
    end
  end

  private

  def set_reported_user
    self.reported_user = case reportable.class.name
                         when "User"
                           reportable
                         when "Note"
                           reportable.author
                         else
                           reportable.user
                         end
  end
end
