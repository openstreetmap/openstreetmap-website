class DiaryComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :diary_entry

  validates_presence_of :body
  validates_associated :diary_entry

  attr_accessible :body

  after_initialize :set_defaults

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

  def set_defaults
    self.body_format = "markdown" unless self.attribute_present?(:body_format)
  end
end
