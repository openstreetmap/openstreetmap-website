class IssueComment < ActiveRecord::Base
	belongs_to :issue
	belongs_to :user

	validates :body, :presence => true
end
