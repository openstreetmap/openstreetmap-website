class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => "User", :foreign_key => :from_user_id
  belongs_to :recipient, :class_name => "User", :foreign_key => :to_user_id

  validates_presence_of :title, :body, :sent_on
  validates_inclusion_of :message_read, :in => [ true, false ]
  validates_associated :sender, :recipient
end
