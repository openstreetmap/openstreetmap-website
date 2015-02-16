class DiaryComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :diary_entry

  validates_presence_of :body
  validates_associated :diary_entry

  after_save :spam_check

  def body
    RichText.new(read_attribute(:body_format), read_attribute(:body))
  end

  def digest
    md5 = Digest::MD5.new
    md5 << diary_entry_id.to_s
    md5 << user_id.to_s
    md5 << created_at.xmlschema
    md5 << body
    md5.hexdigest
  end

  private

  def spam_check
    user.spam_check
  end
end
