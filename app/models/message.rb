# == Schema Information
#
# Table name: messages
#
#  id                :bigint(8)        not null, primary key
#  from_user_id      :bigint(8)        not null
#  title             :string           not null
#  body              :text             not null
#  sent_on           :datetime         not null
#  message_read      :boolean          default(FALSE), not null
#  to_user_id        :bigint(8)        not null
#  to_user_visible   :boolean          default(TRUE), not null
#  from_user_visible :boolean          default(TRUE), not null
#  body_format       :enum             default("markdown"), not null
#
# Indexes
#
#  messages_from_user_id_idx  (from_user_id)
#  messages_to_user_id_idx    (to_user_id)
#
# Foreign Keys
#
#  messages_from_user_id_fkey  (from_user_id => users.id)
#  messages_to_user_id_fkey    (to_user_id => users.id)
#

class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => "User", :foreign_key => :from_user_id
  belongs_to :recipient, :class_name => "User", :foreign_key => :to_user_id

  validates :title, :presence => true, :utf8 => true, :length => 1..255
  validates :body, :sent_on, :sender, :recipient, :presence => true
  validates :title, :body, :characters => true

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
    RichText.new(self[:body_format], self[:body])
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
