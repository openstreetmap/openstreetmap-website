class DiaryEntry < ActiveRecord::Base
  belongs_to :user
  has_many :diary_comments, :order => "id"

  validates_presence_of :title, :body
  validates_length_of :title, :within => 1..255
  validates_length_of :language, :within => 2..3
  validates_numericality_of :latitude, :allow_nil => true
  validates_numericality_of :longitude, :allow_nil => true
  validates_associated :user
end
