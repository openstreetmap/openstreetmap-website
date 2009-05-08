class Hack < ActiveRecord::Base
  set_primary_keys :name
  has_many :comments, :as => :person
  
  has_one :first_comment, :as => :person, :class_name => "Comment"
end