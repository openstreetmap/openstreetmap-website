class User < ActiveRecord::Base
  require 'xml/libxml'

  has_many :traces
  has_many :diary_entries, :order => 'created_at DESC'
  has_many :messages, :foreign_key => :to_user_id, :order => 'sent_on DESC'
  has_many :new_messages, :class_name => "Message", :foreign_key => :to_user_id, :conditions => "message_read = 0", :order => 'sent_on DESC'
  has_many :friends
  has_many :tokens, :class_name => "UserToken"
  has_many :preferences, :class_name => "UserPreference"

  validates_presence_of :email, :display_name
  validates_confirmation_of :pass_crypt, :message => 'Password must match the confirmation password'
  validates_uniqueness_of :display_name, :allow_nil => true
  validates_uniqueness_of :email
  validates_length_of :pass_crypt, :minimum => 8
  validates_length_of :display_name, :minimum => 3, :allow_nil => true
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_format_of :display_name, :with => /^[^\/;.,?]*$/
  validates_numericality_of :home_lat, :allow_nil => true
  validates_numericality_of :home_lon, :allow_nil => true
  validates_numericality_of :home_zoom, :only_integer => true, :allow_nil => true

  before_save :encrypt_password

  def after_initialize
    self.creation_time = Time.now if self.creation_time.nil?
  end

  def encrypt_password
    if pass_crypt_confirmation
      self.pass_salt = OSM::make_token(8)
      self.pass_crypt = OSM::encrypt_password(pass_crypt, pass_salt)
    end
  end

  def self.authenticate(options)
    if options[:username] and options[:password]
      user = find(:first, :conditions => ["email = ? OR display_name = ?", options[:username], options[:username]])
      user = nil if user and user.pass_crypt != OSM::encrypt_password(options[:password], user.pass_salt)
    elsif options[:token]
      token = UserToken.find(:first, :include => :user, :conditions => ["user_tokens.token = ?", options[:token]])
      user = token.user if token
    end

    if user
      user = nil unless user.active? or options[:inactive]
    end

    token.update_attribute(:expiry, 1.week.from_now) if token and user

    return user
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
    if self.home_lat and self.home_lon
      home = XML::Node.new 'home'
      home['lat'] = self.home_lat.to_s
      home['lon'] = self.home_lon.to_s
      home['zoom'] = self.home_zoom.to_s
      el1 << home
    end
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
      if friend.friend_user_id == @new_friend.id
        return true
      end
    end
    return false
  end

end
