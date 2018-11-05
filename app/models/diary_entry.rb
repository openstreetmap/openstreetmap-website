# == Schema Information
#
# Table name: diary_entries
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  title         :string           not null
#  body          :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  latitude      :float
#  longitude     :float
#  language_code :string           default("en"), not null
#  visible       :boolean          default(TRUE), not null
#  body_format   :enum             default("markdown"), not null
#
# Indexes
#
#  diary_entry_created_at_index                (created_at)
#  diary_entry_language_code_created_at_index  (language_code,created_at)
#  diary_entry_user_id_created_at_index        (user_id,created_at)
#
# Foreign Keys
#
#  diary_entries_language_code_fkey  (language_code => languages.code)
#  diary_entries_user_id_fkey        (user_id => users.id)
#

class DiaryEntry < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  belongs_to :language, :foreign_key => "language_code"

  has_many :comments, -> { order(:id).preload(:user) }, :class_name => "DiaryComment"
  has_many :visible_comments, -> { joins(:user).where(:visible => true, :users => { :status => %w[active confirmed] }).order(:id) }, :class_name => "DiaryComment"
  has_many :subscriptions, :class_name => "DiaryEntrySubscription"
  has_many :subscribers, :through => :subscriptions, :source => :user

  scope :visible, -> { where(:visible => true) }

  validates :title, :presence => true, :length => 1..255, :invalid_chars => true
  validates :body, :presence => true, :invalid_chars => true
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
