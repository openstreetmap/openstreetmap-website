class DiaryEntry < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :language, :foreign_key => 'language_code'

  has_many :comments, -> { order(:id).preload(:user) }, :class_name => "DiaryComment"
  has_many :visible_comments, -> { joins(:user).where(:visible => true, :users => { :status => %w(active confirmed) }).order(:id) }, :class_name => "DiaryComment"

  scope :visible, -> { where(:visible => true) }

  validates_presence_of :title, :body
  validates_length_of :title, :within => 1..255
  # validates_length_of :language, :within => 2..5, :allow_nil => false
  validates_numericality_of :latitude, :allow_nil => true,
                                       :greater_than_or_equal_to => -90, :less_than_or_equal_to => 90
  validates_numericality_of :longitude, :allow_nil => true,
                                        :greater_than_or_equal_to => -180, :less_than_or_equal_to => 180
  validates_associated :language

  after_save :spam_check

  def body
    RichText.new(read_attribute(:body_format), read_attribute(:body))
  end

  private

  def spam_check
    user.spam_check
  end
end
