class DiaryEntry < ActiveRecord::Base
  belongs_to :user
  has_many :diary_comments, :order => "id"

  validates_presence_of :title, :body
  validates_numericality_of :latitude, :allow_nil => true
  validates_numericality_of :longitude, :allow_nil => true
  validates_associated :user
end
