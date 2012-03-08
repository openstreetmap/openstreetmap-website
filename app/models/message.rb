require 'validators'

class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => "User", :foreign_key => :from_user_id
  belongs_to :recipient, :class_name => "User", :foreign_key => :to_user_id

  validates_presence_of :title, :body, :sent_on, :sender, :recipient
  validates_length_of :title, :within => 1..255
  validates_inclusion_of :message_read, :in => [ true, false ]
  validates_as_utf8 :title

  attr_accessible :title, :body

  def digest
    md5 = Digest::MD5.new
    md5 << from_user_id.to_s
    md5 << to_user_id.to_s
    md5 << sent_on.xmlschema
    md5 << title
    md5 << body
    md5.hexdigest
  end
end
