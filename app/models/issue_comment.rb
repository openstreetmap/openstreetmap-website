class IssueComment < ActiveRecord::Base
	belongs_to :issue
	belongs_to :user, :class_name => "User", :foreign_key => :commenter_user_id

	validates :body, :presence => true
end
