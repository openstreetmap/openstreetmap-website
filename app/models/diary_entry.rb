class DiaryEntry < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :title, :body
  validates_numericality_of :latitude, :allow_nil => true
  validates_numericality_of :longitude, :allow_nil => true
  validates_associated :user
end
