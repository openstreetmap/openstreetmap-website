require 'validators'

class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => "User", :foreign_key => :from_user_id
  belongs_to :recipient, :class_name => "User", :foreign_key => :to_user_id

  validates_presence_of :title, :body, :sent_on, :sender, :recipient
  validates_length_of :title, :within => 1..255
  validates_inclusion_of :message_read, :in => [true, false]
  validates_as_utf8 :title

  def self.from_mail(mail, from, to)
    if mail.multipart?
      if mail.text_part
        body = mail.text_part.decoded
      elsif mail.html_part
        body = HTMLEntities.new.decode(Sanitize.clean(mail.html_part.decoded))
      end
    elsif mail.text? && mail.sub_type == "html"
      body = HTMLEntities.new.decode(Sanitize.clean(mail.decoded))
    else
      body = mail.decoded
    end

    Message.new(
      :sender => from,
      :recipient => to,
      :sent_on => mail.date.new_offset(0),
      :title => mail.subject.sub(/\[OpenStreetMap\] */, ""),
      :body => body,
      :body_format => "text"
    )
  end

  def body
    RichText.new(read_attribute(:body_format), read_attribute(:body))
  end

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
