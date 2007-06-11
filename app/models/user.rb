class User < ActiveRecord::Base
  require 'xml/libxml'
  require 'digest/md5'

  has_many :traces
  has_many :diary_entries
  has_many :messages, :foreign_key => :to_user_id
  has_many :friends

  validates_confirmation_of :pass_crypt, :message => 'Password must match the confirmation password'
  validates_uniqueness_of :display_name, :allow_nil => true
  validates_uniqueness_of :email
  validates_length_of :pass_crypt, :minimum => 8
  validates_length_of :display_name, :minimum => 3, :allow_nil => true
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_format_of :display_name, :with => /^[^\/;.,?]*$/

  before_save :encrypt_password

  def set_defaults
    self.creation_time = Time.now
    self.timeout = Time.now
    self.token = User.make_token()
  end

  def encrypt_password
    self.pass_crypt = Digest::MD5.hexdigest(pass_crypt) if pass_crypt_confirmation
  end

  def self.authenticate(email, passwd)
    find(:first, :conditions => [ "email = ? AND pass_crypt = ? AND active = true", email, Digest::MD5.hexdigest(passwd)])
  end 

  def self.authenticate_token(token) 
    find(:first, :conditions => [ "token = ? ", token])
  end 

  def self.make_token(length=30)
    chars = 'abcdefghijklmnopqrtuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    confirmstring = ''

    length.times do
      confirmstring += chars[(rand * chars.length).to_i].chr
    end

    return confirmstring
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node
    el1 = XML::Node.new 'user'
    el1['display_name'] = self.display_name.to_s
    el1['account_created'] = self.creation_time.xmlschema
    return el1
  end

  def nearby(lat_range=1, lon_range=1)
      if self.home_lon and self.home_lat 
          nearby = User.find(:all,  :conditions => "#{self.home_lon} > home_lon - #{lon_range} and #{self.home_lon} < home_lon + #{lon_range} and  #{self.home_lat} > home_lat - #{lat_range} and #{self.home_lat} < home_lat + #{lat_range} and data_public = 1 and id != #{self.id}") 
      else
          nearby = []
      end
      return nearby
  end

  def self.has_messages?
    if Message.fdhjklsafind_by_to_user_id(self.id) 
      return true
    else
      return false
    end
  end

  def get_new_messages
    messages = Message.find(:all, :conditions => "message_read = 0 and to_user_id = #{self.id}")
    return messages
  end

  def get_all_messages
    messages = Message.find(:all, :conditions => "to_user_id = #{self.id}")
    return messages
  end

  def is_friends_with?(new_friend)
    res = false
    @new_friend = new_friend
    self.friends.each do |friend|
      if friend.user_id == @new_friend.user_id
        return true
      end
    end
    return false
  end

end
