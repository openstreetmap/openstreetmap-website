class DiaryEntry < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :language, :foreign_key => "language_code"

  has_many :comments, -> { order(:id).preload(:user) }, :class_name => "DiaryComment"
  has_many :visible_comments, -> { joins(:user).where(:visible => true, :users => { :status => %w(active confirmed) }).order(:id) }, :class_name => "DiaryComment"

  scope :visible, -> { where(:visible => true) }

  validates :title, :body, :presence => true
  validates :title, :length => 1..255
  validates :latitude, :allow_nil => true,
                       :numericality => { :greater_than_or_equal_to => -90,
                                          :less_than_or_equal_to => 90 }
  validates :longitude, :allow_nil => true,
                        :numericality => { :greater_than_or_equal_to => -180,
                                           :less_than_or_equal_to => 180 }
  validates :language, :user, :associated => true

  after_save :spam_check

  def body
    RichText.new(self[:body_format], self[:body])
  end

  private

  def spam_check
    user.spam_check
  end
end
