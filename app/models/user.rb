class User < ActiveRecord::Base
  require 'xml/libxml'
  require 'digest/md5'

  has_many :traces
  has_many :diary_entries, :order => 'created_at DESC'
  has_many :messages, :foreign_key => :to_user_id
  has_many :new_messages, :class_name => "Message", :foreign_key => :to_user_id, :conditions => "message_read = 0"
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
    self.pass_crypt = Digest::MD5.hexdigest(pass_crypt) unless pass_crypt_confirmation.nil?
  end

  def self.authenticate(email, passwd, active = true)
    find(:first, :conditions => [ "email = ? AND pass_crypt = ? AND active = ?", email, Digest::MD5.hexdigest(passwd), active])
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

  def nearby(radius = 50)
    if self.home_lon and self.home_lat 
      gc = OSM::GreatCircle.new(self.home_lat, self.home_lon)
      bounds = gc.bounds(radius)
      nearby = User.find(:all, :conditions => "home_lat between #{bounds[:minlat]} and #{bounds[:maxlat]} and home_lon between #{bounds[:minlon]} and #{bounds[:maxlon]} and data_public = 1 and id != #{self.id}")
      nearby.delete_if { |u| gc.distance(u.home_lat, u.home_lon) > radius }
      nearby.sort! { |u1,u2| gc.distance(u1.home_lat, u1.home_lon) <=> gc.distance(u2.home_lat, u2.home_lon) }
    else
      nearby = []
    end
    return nearby
  end

  def distance(nearby_user)
    return OSM::GreatCircle.new(self.home_lat, self.home_lon).distance(nearby_user.home_lat, nearby_user.home_lon)
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
