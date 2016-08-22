class Report < ActiveRecord::Base
  belongs_to :issue
  belongs_to :user, :class_name => "User", :foreign_key => :reporter_user_id
end
