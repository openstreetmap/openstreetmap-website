class DiaryComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :diary_entry

  validates_presence_of :body
  validates_associated :diary_entry
end
