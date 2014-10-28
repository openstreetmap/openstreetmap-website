class User < ActiveRecord::Base
  require 'xml/libxml'

  has_many :traces, -> { where(:visible => true) }
  has_many :diary_entries, -> { order(:created_at => :desc) }
  has_many :diary_comments, -> { order(:created_at => :desc) }
  has_many :messages, -> { where(:to_user_visible => true).order(:sent_on => :desc).preload(:sender, :recipient) }, :foreign_key => :to_user_id
  has_many :new_messages, -> { where(:to_user_visible => true, :message_read => false).order(:sent_on => :desc) }, :class_name => "Message", :foreign_key => :to_user_id
  has_many :sent_messages, -> { where(:from_user_visible => true).order(:sent_on => :desc).preload(:sender, :recipient) }, :class_name => "Message", :foreign_key => :from_user_id
  has_many :friends, -> { joins(:befriendee).where(:users => { :status => ["active", "confirmed"] }) }
  has_many :friend_users, :through => :friends, :source => :befriendee
  has_many :tokens, :class_name => "UserToken"
  has_many :preferences, :class_name => "UserPreference"
  has_many :changesets, -> { order(:created_at => :desc) }
  has_many :changeset_comments, :foreign_key =>  'author_id'
  has_and_belongs_to_many :changeset_subscriptions, :class_name => 'Changeset', :join_table => 'changesets_subscribers', :foreign_key => 'subscriber_id'
  has_many :note_comments, :foreign_key => :author_id
  has_many :notes, :through => :note_comments

  has_many :client_applications
  has_many :oauth_tokens, -> { order(:authorized_at => :desc).preload(:client_application) }, :class_name => "OauthToken"

  has_many :blocks, :class_name => "UserBlock"
  has_many :blocks_created, :class_name => "UserBlock", :foreign_key => :creator_id
  has_many :blocks_revoked, :class_name => "UserBlock", :foreign_key => :revoker_id

  has_many :roles, :class_name => "UserRole"

  scope :visible, -> { where(:status => ["pending", "active", "confirmed"]) }
  scope :active, -> { where(:status => ["active", "confirmed"]) }
  scope :identifiable, -> { where(:data_public => true) }

  has_attached_file :image,
    :default_url => "/assets/:class/:attachment/:style.png",
    :styles => { :large => "100x100>", :small => "50x50>" }

  validates_presence_of :email, :display_name
  validates_confirmation_of :email#, :message => ' addresses must match'
  validates_confirmation_of :pass_crypt#, :message => ' must match the confirmation password'
  validates_uniqueness_of :display_name, :allow_nil => true, :case_sensitive => false, :if => Proc.new { |u| u.display_name_changed? }
  validates_uniqueness_of :email, :case_sensitive => false, :if => Proc.new { |u| u.email_changed? }
  validates_uniqueness_of :openid_url, :allow_nil => true
  validates_length_of :pass_crypt, :within => 8..255
  validates_length_of :display_name, :within => 3..255, :allow_nil => true
  validates_email_format_of :email, :if => Proc.new { |u| u.email_changed? }
  validates_email_format_of :new_email, :allow_blank => true, :if => Proc.new { |u| u.new_email_changed? }
  validates_format_of :display_name, :with => /\A[^\x00-\x1f\x7f\ufffe\uffff\/;.,?%#]*\z/, :if => Proc.new { |u| u.display_name_changed? }
  validates_format_of :display_name, :with => /\A\S/, :message => "has leading whitespace", :if => Proc.new { |u| u.display_name_changed? }
  validates_format_of :display_name, :with => /\S\z/, :message => "has trailing whitespace", :if => Proc.new { |u| u.display_name_changed? }
  validates_exclusion_of :display_name, :in => %w(new terms save confirm confirm-email go_public reset-password forgot-password suspended)
  validates_numericality_of :home_lat, :allow_nil => true
  validates_numericality_of :home_lon, :allow_nil => true
  validates_numericality_of :home_zoom, :only_integer => true, :allow_nil => true
  validates_inclusion_of :preferred_editor, :in => Editors::ALL_EDITORS, :allow_nil => true
  validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/

  after_initialize :set_defaults
  before_save :encrypt_password
  after_save :spam_check

  def self.authenticate(options)
    if options[:username] and options[:password]
      user = where("email = ? OR display_name = ?", options[:username], options[:username]).first

      if user.nil?
        users = where("LOWER(email) = LOWER(?) OR LOWER(display_name) = LOWER(?)", options[:username], options[:username])

        if users.count == 1
          user = users.first
        end
      end

      if user and PasswordHash.check(user.pass_crypt, user.pass_salt, options[:password])
        if PasswordHash.upgrade?(user.pass_crypt, user.pass_salt)
          user.pass_crypt, user.pass_salt = PasswordHash.create(options[:password])
          user.save
        end
      else
        user = nil
      end
    elsif options[:token]
      token = UserToken.find_by_token(options[:token])
      user = token.user if token
    end

    if user and
      ( user.status == "deleted" or
        ( user.status == "pending" and not options[:pending] ) or
        ( user.status == "suspended" and not options[:suspended] ) )
      user = nil
    end

    token.update_column(:expiry, 1.week.from_now) if token and user

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

  def description
    RichText.new(read_attribute(:description_format), read_attribute(:description))
  end

  def languages
    attribute_present?(:languages) ? read_attribute(:languages).split(/ *, */) : []
  end

  def languages=(languages)
    write_attribute(:languages, languages.join(","))
  end

  def preferred_language
    languages.find { |l| Language.exists?(:code => l) }
  end

  def preferred_language_from(array)
    (languages & array.collect { |i| i.to_s }).first
  end

  def nearby(radius = NEARBY_RADIUS, num = NEARBY_USERS)
    if self.home_lon and self.home_lat
      gc = OSM::GreatCircle.new(self.home_lat, self.home_lon)
      bounds = gc.bounds(radius)
      sql_for_distance = gc.sql_for_distance("home_lat", "home_lon")
      nearby = User.where("id != ? AND status IN (\'active\', \'confirmed\') AND data_public = ? AND #{sql_for_distance} <= ?", id, true, radius).order(sql_for_distance).limit(num)
    else
      nearby = []
    end
    return nearby
  end

  def distance(nearby_user)
    return OSM::GreatCircle.new(self.home_lat, self.home_lon).distance(nearby_user.home_lat, nearby_user.home_lon)
  end

  def is_friends_with?(new_friend)
    self.friends.where(:friend_user_id => new_friend.id).exists?
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
    blocks.active.detect { |b| b.needs_view? }
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
    self.openid_url = nil
    self.status = "deleted"
    self.save
  end

  ##
  # return a spam score for a user
  def spam_score
    changeset_score = self.changesets.size * 50
    trace_score = self.traces.size * 50
    diary_entry_score = self.diary_entries.inject(0) { |s,e| s += e.body.spam_score }
    diary_comment_score = self.diary_comments.inject(0) { |s,c| s += c.body.spam_score }

    score = self.description.spam_score / 4.0
    score += diary_entry_score / self.diary_entries.length if self.diary_entries.length > 0
    score += diary_comment_score / self.diary_comments.length if self.diary_comments.length > 0
    score -= changeset_score
    score -= trace_score

    return score.to_i
  end

  ##
  # perform a spam check on a user
  def spam_check
    if status == "active" and spam_score > SPAM_THRESHOLD
      update_column(:status, "suspended")
    end
  end

  ##
  # return an oauth access token for a specified application
  def access_token(application_key)
    return ClientApplication.find_by_key(application_key).access_token_for_user(self)
  end

private

  def set_defaults
    self.creation_time = Time.now.getutc unless self.attribute_present?(:creation_time)
    self.description_format = "markdown" unless self.attribute_present?(:description_format)
  end

  def encrypt_password
    if pass_crypt_confirmation
      self.pass_crypt, self.pass_salt = PasswordHash.create(pass_crypt)
      self.pass_crypt_confirmation = nil
    end
  end
end
