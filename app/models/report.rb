class Report < ActiveRecord::Base
  belongs_to :issue, :counter_cache => true
  belongs_to :user, :class_name => "User", :foreign_key => :reporter_user_id
end
