class Group < ActiveRecord::Base
  has_many :users, :class_name => "User",
                      :foreign_key => :user_id,
                      :conditions => { :visible => true }

  validates_presence_of :id, :on => :update
  validates_uniqueness_of :id

  attr_accessible :title, :description

private
end
