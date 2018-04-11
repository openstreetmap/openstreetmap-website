# == Schema Information
#
# Table name: users
#
#  email               :string           not null
#  id                  :integer          not null, primary key
#  pass_crypt          :string           not null
#  creation_time       :datetime         not null
#  display_name        :string           default(""), not null
#  data_public         :boolean          default(FALSE), not null
#  description         :text             default(""), not null
#  home_lat            :float
#  home_lon            :float
#  home_zoom           :integer          default(3)
#  nearby              :integer          default(50)
#  pass_salt           :string
#  image_file_name     :text
#  email_valid         :boolean          default(FALSE), not null
#  new_email           :string
#  creation_ip         :string
#  languages           :string
#  status              :enum             default("pending"), not null
#  terms_agreed        :datetime
#  consider_pd         :boolean          default(FALSE), not null
#  auth_uid            :string
#  preferred_editor    :string
#  terms_seen          :boolean          default(FALSE), not null
#  description_format  :enum             default("markdown"), not null
#  image_fingerprint   :string
#  changesets_count    :integer          default(0), not null
#  traces_count        :integer          default(0), not null
#  diary_entries_count :integer          default(0), not null
#  image_use_gravatar  :boolean          default(FALSE), not null
#  image_content_type  :string
#  auth_provider       :string
#  home_tile           :integer
#
# Indexes
#
#  users_auth_idx                (auth_provider,auth_uid) UNIQUE
#  users_display_name_idx        (display_name) UNIQUE
#  users_display_name_lower_idx  (lower((display_name)::text))
#  users_email_idx               (email) UNIQUE
#  users_email_lower_idx         (lower((email)::text))
#  users_home_idx                (home_tile)
#

class User < ActiveRecord::Base
  require "xml/libxml"

  has_many :traces, -> { where(:visible => true) }
  has_many :diary_entries, -> { order(:created_at => :desc) }
  has_many :diary_comments, -> { order(:created_at => :desc) }
  has_many :diary_entry_subscriptions, :class_name => "DiaryEntrySubscription"
  has_many :diary_subscriptions, :through => :diary_entry_subscriptions, :source => :diary_entry
  has_many :messages, -> { where(:to_user_visible => true).order(:sent_on => :desc).preload(:sender, :recipient) }, :foreign_key => :to_user_id
  has_many :new_messages, -> { where(:to_user_visible => true, :message_read => false).order(:sent_on => :desc) }, :class_name => "Message", :foreign_key => :to_user_id
  has_many :sent_messages, -> { where(:from_user_visible => true).order(:sent_on => :desc).preload(:sender, :recipient) }, :class_name => "Message", :foreign_key => :from_user_id
  has_many :friends, -> { joins(:befriendee).where(:users => { :status => %w[active confirmed] }) }
  has_many :friend_users, :through => :friends, :source => :befriendee
  has_many :tokens, :class_name => "UserToken"
  has_many :preferences, :class_name => "UserPreference"
  has_many :changesets, -> { order(:created_at => :desc) }
  has_many :changeset_comments, :foreign_key => :author_id
  has_and_belongs_to_many :changeset_subscriptions, :class_name => "Changeset", :join_table => "changesets_subscribers", :foreign_key => "subscriber_id"
  has_many :note_comments, :foreign_key => :author_id
  has_many :notes, :through => :note_comments

  has_many :client_applications
  has_many :oauth_tokens, -> { order(:authorized_at => :desc).preload(:client_application) }, :class_name => "OauthToken"

  has_many :blocks, :class_name => "UserBlock"
  has_many :blocks_created, :class_name => "UserBlock", :foreign_key => :creator_id
  has_many :blocks_revoked, :class_name => "UserBlock", :foreign_key => :revoker_id

  has_many :roles, :class_name => "UserRole"

  has_many :issues, :class_name => "Issue", :foreign_key => :reported_user_id
  has_many :issue_comments

  has_many :reports

  scope :visible, -> { where(:status => %w[pending active confirmed]) }
  scope :active, -> { where(:status => %w[active confirmed]) }
  scope :identifiable, -> { where(:data_public => true) }

  has_attached_file :image,
                    :default_url => "/assets/:class/:attachment/:style.png",
                    :styles => { :large => "100x100>", :small => "50x50>" }

  validates :display_name, :presence => true, :allow_nil => true, :length => 3..255,
                           :exclusion => %w[new terms save confirm confirm-email go_public reset-password forgot-password suspended]
  validates :display_name, :if => proc { |u| u.display_name_changed? },
                           :uniqueness => { :case_sensitive => false }
  validates :display_name, :if => proc { |u| u.display_name_changed? },
                           :format => { :with => %r{\A[^\x00-\x1f\x7f\ufffe\uffff/;.,?%#]*\z} }
  validates :display_name, :if => proc { |u| u.display_name_changed? },
                           :format => { :with => /\A\S/, :message => "has leading whitespace" }
  validates :display_name, :if => proc { |u| u.display_name_changed? },
                           :format => { :with => /\S\z/, :message => "has trailing whitespace" }
  validates :email, :presence => true, :confirmation => true
  validates :email, :if => proc { |u| u.email_changed? },
                    :uniqueness => { :case_sensitive => false }
  validates :pass_crypt, :confirmation => true, :length => 8..255
  validates :home_lat, :allow_nil => true, :numericality => true, :inclusion => { :in => -90..90 }
  validates :home_lon, :allow_nil => true, :numericality => true, :inclusion => { :in => -180..180 }
  validates :home_zoom, :allow_nil => true, :numericality => { :only_integer => true }
  validates :preferred_editor, :inclusion => Editors::ALL_EDITORS, :allow_nil => true
  validates :image, :attachment_content_type => { :content_type => %r{\Aimage/.*\Z} }
  validates :auth_uid, :unless => proc { |u| u.auth_provider.nil? },
                       :uniqueness => { :scope => :auth_provider }

  validates_email_format_of :email, :if => proc { |u| u.email_changed? }
  validates_email_format_of :new_email, :allow_blank => true, :if => proc { |u| u.new_email_changed? }

  after_initialize :set_defaults
  before_save :encrypt_password
  before_save :update_tile
  after_save :spam_check

  def to_param
    display_name
  end

  def self.authenticate(options)
    if options[:username] && options[:password]
      user = find_by("email = ? OR display_name = ?", options[:username], options[:username])

      if user.nil?
        users = where("LOWER(email) = LOWER(?) OR LOWER(display_name) = LOWER(?)", options[:username], options[:username])

        user = users.first if users.count == 1
      end

      if user && PasswordHash.check(user.pass_crypt, user.pass_salt, options[:password])
        if PasswordHash.upgrade?(user.pass_crypt, user.pass_salt)
          user.pass_crypt, user.pass_salt = PasswordHash.create(options[:password])
          user.save
        end
      else
        user = nil
      end
    elsif options[:token]
      token = UserToken.find_by(:token => options[:token])
      user = token.user if token
    end

    if user &&
       (user.status == "deleted" ||
         (user.status == "pending" && !options[:pending]) ||
         (user.status == "suspended" && !options[:suspended]))
      user = nil
    end

    token.update(:expiry => 1.week.from_now) if token && user

    user
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node
    doc
  end

  def to_xml_node
    el1 = XML::Node.new "user"
    el1["display_name"] = display_name.to_s
    el1["account_created"] = creation_time.xmlschema
    if home_lat && home_lon
      home = XML::Node.new "home"
      home["lat"] = home_lat.to_s
      home["lon"] = home_lon.to_s
      home["zoom"] = home_zoom.to_s
      el1 << home
    end
    el1
  end

  def description
    RichText.new(self[:description_format], self[:description])
  end

  def languages
    attribute_present?(:languages) ? self[:languages].split(/ *[, ] */) : []
  end

  def languages=(languages)
    self[:languages] = languages.join(",")
  end

  def preferred_language
    languages.find { |l| Language.exists?(:code => l) }
  end

  def preferred_languages
    @preferred_languages ||= Locale.list(languages)
  end

  def nearby(radius = NEARBY_RADIUS, num = NEARBY_USERS)
    if home_lon && home_lat
      gc = OSM::GreatCircle.new(home_lat, home_lon)
      sql_for_area = QuadTile.sql_for_area(gc.bounds(radius), "home_")
      sql_for_distance = gc.sql_for_distance("home_lat", "home_lon")
      nearby = User.active.identifiable
                   .where("id != ?", id)
                   .where(sql_for_area)
                   .where("#{sql_for_distance} <= ?", radius)
                   .order(sql_for_distance)
                   .limit(num)
    else
      nearby = []
    end
    nearby
  end

  def distance(nearby_user)
    OSM::GreatCircle.new(home_lat, home_lon).distance(nearby_user.home_lat, nearby_user.home_lon)
  end

  def is_friends_with?(new_friend)
    friends.where(:friend_user_id => new_friend.id).exists?
  end

  ##
  # returns true if a user is visible
  def visible?
    %w[pending active confirmed].include? status
  end

  ##
  # returns true if a user is active
  def active?
    %w[active confirmed].include? status
  end

  ##
  # returns true if the user has the moderator role, false otherwise
  def moderator?
    has_role? "moderator"
  end

  ##
  # returns true if the user has the administrator role, false otherwise
  def administrator?
    has_role? "administrator"
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
    blocks.active.detect(&:needs_view?)
  end

  ##
  # delete a user - leave the account but purge most personal data
  def delete
    self.display_name = "user_#{id}"
    self.description = ""
    self.home_lat = nil
    self.home_lon = nil
    self.image = nil
    self.email_valid = false
    self.new_email = nil
    self.auth_provider = nil
    self.auth_uid = nil
    self.status = "deleted"
    save
  end

  ##
  # return a spam score for a user
  def spam_score
    changeset_score = changesets.size * 50
    trace_score = traces.size * 50
    diary_entry_score = diary_entries.visible.inject(0) { |acc, elem| acc + elem.body.spam_score }
    diary_comment_score = diary_comments.visible.inject(0) { |acc, elem| acc + elem.body.spam_score }

    score = description.spam_score / 4.0
    score += diary_entries.where("created_at > ?", 1.day.ago).count * 10
    score += diary_entry_score / diary_entries.length unless diary_entries.empty?
    score += diary_comment_score / diary_comments.length unless diary_comments.empty?
    score -= changeset_score
    score -= trace_score

    score.to_i
  end

  ##
  # perform a spam check on a user
  def spam_check
    update(:status => "suspended") if status == "active" && spam_score > SPAM_THRESHOLD
  end

  ##
  # return an oauth access token for a specified application
  def access_token(application_key)
    ClientApplication.find_by(:key => application_key).access_token_for_user(self)
  end

  private

  def set_defaults
    self.creation_time = Time.now.getutc unless attribute_present?(:creation_time)
  end

  def encrypt_password
    if pass_crypt_confirmation
      self.pass_crypt, self.pass_salt = PasswordHash.create(pass_crypt)
      self.pass_crypt_confirmation = nil
    end
  end

  def update_tile
    self.home_tile = QuadTile.tile_for_point(home_lat, home_lon) if home_lat && home_lon
  end
end
