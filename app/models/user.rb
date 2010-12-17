class User < ActiveRecord::Base
  require 'xml/libxml'

  has_many :traces, :conditions => { :visible => true }
  has_many :diary_entries, :order => 'created_at DESC'
  has_many :diary_comments, :order => 'created_at DESC'
  has_many :messages, :foreign_key => :to_user_id, :conditions => { :to_user_visible => true }, :order => 'sent_on DESC'
  has_many :new_messages, :class_name => "Message", :foreign_key => :to_user_id, :conditions => { :to_user_visible => true, :message_read => false }, :order => 'sent_on DESC'
  has_many :sent_messages, :class_name => "Message", :foreign_key => :from_user_id, :conditions => { :from_user_visible => true }, :order => 'sent_on DESC'
  has_many :friends, :include => :befriendee, :conditions => "users.status IN ('active', 'confirmed')"
  has_many :tokens, :class_name => "UserToken"
  has_many :preferences, :class_name => "UserPreference"
  has_many :changesets, :order => 'created_at DESC'

  has_many :client_applications
  has_many :oauth_tokens, :class_name => "OauthToken", :order => "authorized_at desc", :include => [:client_application]

  has_many :active_blocks, :class_name => "UserBlock", :conditions => ['user_blocks.ends_at > \'#{Time.now.getutc.xmlschema(5)}\' or user_blocks.needs_view']
  has_many :roles, :class_name => "UserRole"

  validates_presence_of :email, :display_name
  validates_confirmation_of :email#, :message => ' addresses must match'
  validates_confirmation_of :pass_crypt#, :message => ' must match the confirmation password'
  validates_uniqueness_of :display_name, :allow_nil => true
  validates_uniqueness_of :email
  validates_length_of :pass_crypt, :within => 8..255
  validates_length_of :display_name, :within => 3..255, :allow_nil => true
  validates_email_format_of :email
  validates_email_format_of :new_email, :allow_blank => true
  validates_format_of :display_name, :with => /^[^\/;.,?]*$/
  validates_format_of :display_name, :with => /^\S/, :message => "has leading whitespace"
  validates_format_of :display_name, :with => /\S$/, :message => "has trailing whitespace"
  validates_numericality_of :home_lat, :allow_nil => true
  validates_numericality_of :home_lon, :allow_nil => true
  validates_numericality_of :home_zoom, :only_integer => true, :allow_nil => true
  validates_inclusion_of :preferred_editor, :in => Editors::ALL_EDITORS, :allow_nil => true

  before_save :encrypt_password

  file_column :image, :magick => { :geometry => "100x100>" }

  def after_initialize
    self.creation_time = Time.now.getutc unless self.attribute_present?(:creation_time)
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

    if user and
      ( user.status == "deleted" or
        ( user.status == "pending" and not options[:pending] ) or
        ( user.status == "suspended" and not options[:suspended] ) )
      user = nil
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

  def languages
    attribute_present?(:languages) ? read_attribute(:languages).split(/ *, */) : []
  end

  def languages=(languages)
    write_attribute(:languages, languages.join(","))
  end

  def preferred_language
    languages.find { |l| Language.find(:first, :conditions => { :code => l }) }
  end

  def preferred_language_from(array)
    (languages & array.collect { |i| i.to_s }).first
  end

  def nearby(radius = NEARBY_RADIUS, num = NEARBY_USERS)
    if self.home_lon and self.home_lat 
      gc = OSM::GreatCircle.new(self.home_lat, self.home_lon)
      bounds = gc.bounds(radius)
      sql_for_distance = gc.sql_for_distance("home_lat", "home_lon")
      nearby = User.find(:all, 
                         :conditions => ["id != ? AND status IN (\'active\', \'confirmed\') AND data_public = ? AND #{sql_for_distance} <= ?", id, true, radius],
                         :order => sql_for_distance, :limit => num)
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

  ##
  # returns true if a user is visible
  def visible?
    ["pending","active","confirmed"].include? self.status
  end

  ##
  # returns true if a user is active
  def active?
    ["active","confirmed"].include? self.status
  end

  ##
  # returns true if the user has the moderator role, false otherwise
  def moderator?
    has_role? 'moderator'
  end

  ##
  # returns true if the user has the administrator role, false otherwise
  def administrator?
    has_role? 'administrator'
  end

  ##
  # returns true if the user has the requested role
  def has_role?(role)
    roles.any? { |r| r.role == role }
  end

  ##
  # returns the first active block which would require users to view 
  # a message, or nil if there are none.
  def blocked_on_view
    active_blocks.detect { |b| b.needs_view? }
  end

  ##
  # delete a user - leave the account but purge most personal data
  def delete
    self.display_name = "user_#{self.id}"
    self.description = ""
    self.home_lat = nil
    self.home_lon = nil
    self.image = nil
    self.email_valid = false
    self.new_email = nil
    self.status = "deleted"
    self.save
  end

  ##
  # return a spam score for a user
  def spam_score
    changeset_score = self.changesets.find(:all, :limit => 10).length * 50
    trace_score = self.traces.find(:all, :limit => 10).length * 50
    diary_entry_score = self.diary_entries.inject(0) { |s,e| s += OSM.spam_score(e.body) }
    diary_comment_score = self.diary_comments.inject(0) { |s,e| s += OSM.spam_score(e.body) }

    score = OSM.spam_score(self.description) * 2
    score += diary_entry_score / self.diary_entries.length if self.diary_entries.length > 0
    score += diary_comment_score / self.diary_comments.length if self.diary_comments.length > 0
    score -= changeset_score
    score -= trace_score

    return score.to_i
  end

  ##
  # return an oauth access token for a specified application
  def access_token(application_key)
    return ClientApplication.find_by_key(application_key).access_token_for_user(self)
  end
end
