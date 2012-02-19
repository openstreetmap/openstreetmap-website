class DiaryEntry < ActiveRecord::Base
  # including for #truncate. Makes a similar API for diaries & changesets.
  include ActionView::Helpers::TextHelper


  belongs_to :user
  belongs_to :language, :foreign_key => 'language_code'
  
  has_many :comments, :class_name => "DiaryComment",
                      :include => :user,
                      :order => "diary_comments.id"
  has_many :visible_comments, :class_name => "DiaryComment",
                              :include => :user,
                              :conditions => {
                                :users => { :status => ["active", "confirmed" ] },
                                :visible => true
                              },
                              :order => "diary_comments.id"

  scope :visible, where(:visible => true)

  validates_presence_of :title, :body
  validates_length_of :title, :within => 1..255
  #validates_length_of :language, :within => 2..5, :allow_nil => false
  validates_numericality_of :latitude, :allow_nil => true,
                            :greater_than_or_equal_to => -90, :less_than_or_equal_to => 90
  validates_numericality_of :longitude, :allow_nil => true,
                            :greater_than_or_equal_to => -180, :less_than_or_equal_to => 180
  validates_associated :language


  # Determines the best 'summary' of the diary
  def summary
    truncate(self.body, :length => 50)
  end  
end
