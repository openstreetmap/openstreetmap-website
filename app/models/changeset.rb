# == Schema Information
#
# Table name: changesets
#
#  id          :bigint(8)        not null, primary key
#  user_id     :bigint(8)        not null
#  created_at  :datetime         not null
#  min_lat     :integer
#  max_lat     :integer
#  min_lon     :integer
#  max_lon     :integer
#  closed_at   :datetime         not null
#  num_changes :integer          default(0), not null
#
# Indexes
#
#  changesets_bbox_idx                (min_lat,max_lat,min_lon,max_lon) USING gist
#  changesets_closed_at_idx           (closed_at)
#  changesets_created_at_idx          (created_at)
#  changesets_user_id_created_at_idx  (user_id,created_at)
#  changesets_user_id_id_idx          (user_id,id)
#
# Foreign Keys
#
#  changesets_user_id_fkey  (user_id => users.id)
#

class Changeset < ApplicationRecord
  require "xml/libxml"

  belongs_to :user, :counter_cache => true

  has_many :changeset_tags

  has_many :nodes
  has_many :ways
  has_many :relations
  has_many :old_nodes
  has_many :old_ways
  has_many :old_relations

  has_many :comments, -> { where(:visible => true).order(:created_at) }, :class_name => "ChangesetComment"
  has_and_belongs_to_many :subscribers, :class_name => "User", :join_table => "changesets_subscribers", :association_foreign_key => "subscriber_id"

  validates :id, :uniqueness => true, :presence => { :on => :update },
                 :numericality => { :on => :update, :only_integer => true }
  validates :num_changes, :presence => true,
                          :numericality => { :only_integer => true,
                                             :greater_than_or_equal_to => 0 }
  validates :created_at, :closed_at, :presence => true
  validates :min_lat, :max_lat, :min_lon, :max_lat, :allow_nil => true,
                                                    :numericality => { :only_integer => true }

  before_save :update_closed_at

  # maximum number of elements allowed in a changeset
  MAX_ELEMENTS = 10000

  # maximum time a changeset is allowed to be open for.
  MAX_TIME_OPEN = 1.day

  # idle timeout increment, one hour seems reasonable.
  IDLE_TIMEOUT = 1.hour

  # Use a method like this, so that we can easily change how we
  # determine whether a changeset is open, without breaking code in at
  # least 6 controllers
  def open?
    # a changeset is open (that is, it will accept further changes) when
    # it has not yet run out of time and its capacity is small enough.
    # note that this may not be a hard limit - due to timing changes and
    # concurrency it is possible that some changesets may be slightly
    # longer than strictly allowed or have slightly more changes in them.
    ((closed_at > Time.now.utc) && (num_changes <= MAX_ELEMENTS))
  end

  def set_closed_time_now
    self.closed_at = Time.now.utc if open?
  end

  def self.from_xml(xml, create: false)
    p = XML::Parser.string(xml, :options => XML::Parser::Options::NOERROR)
    doc = p.parse
    pt = doc.find_first("//osm/changeset")

    if pt
      Changeset.from_xml_node(pt, :create => create)
    else
      raise OSM::APIBadXMLError.new("changeset", xml, "XML doesn't contain an osm/changeset element.")
    end
  rescue LibXML::XML::Error, ArgumentError => e
    raise OSM::APIBadXMLError.new("changeset", xml, e.message)
  end

  def self.from_xml_node(pt, create: false)
    cs = Changeset.new
    if create
      cs.created_at = Time.now.utc
      # initial close time is 1h ahead, but will be increased on each
      # modification.
      cs.closed_at = cs.created_at + IDLE_TIMEOUT
      # initially we have no changes in a changeset
      cs.num_changes = 0
    end

    pt.find("tag").each do |tag|
      raise OSM::APIBadXMLError.new("changeset", pt, "tag is missing key") if tag["k"].nil?
      raise OSM::APIBadXMLError.new("changeset", pt, "tag is missing value") if tag["v"].nil?

      cs.add_tag_keyval(tag["k"], tag["v"])
    end

    cs
  end

  ##
  # returns the bounding box of the changeset. it is possible that some
  # or all of the values will be nil, indicating that they are undefined.
  def bbox
    @bbox ||= BoundingBox.new(min_lon, min_lat, max_lon, max_lat)
  end

  def bbox_valid?
    bbox.complete?
  end

  ##
  # expand the bounding box to include the given bounding box.
  def update_bbox!(bbox_update)
    bbox.expand!(bbox_update)

    # update active record. rails 2.1's dirty handling should take care of
    # whether this object needs saving or not.
    self.min_lon, self.min_lat, self.max_lon, self.max_lat = @bbox.to_a.collect(&:round) if bbox.complete?
  end

  ##
  # the number of elements is also passed in so that we can ensure that
  # a single changeset doesn't contain too many elements.
  def add_changes!(elements)
    self.num_changes += elements
  end

  def tags
    unless @tags
      @tags = {}
      changeset_tags.each do |tag|
        @tags[tag.k] = tag.v
      end
    end
    @tags
  end

  attr_writer :tags

  def add_tag_keyval(k, v)
    @tags ||= {}

    # duplicate tags are now forbidden, so we can't allow values
    # in the hash to be overwritten.
    raise OSM::APIDuplicateTagsError.new("changeset", id, k) if @tags.include? k

    @tags[k] = v
  end

  def save_with_tags!
    # do the changeset update and the changeset tags update in the
    # same transaction to ensure consistency.
    Changeset.transaction do
      save!

      tags = self.tags
      ChangesetTag.where(:changeset_id => id).delete_all

      tags.each do |k, v|
        tag = ChangesetTag.new
        tag.changeset_id = id
        tag.k = k
        tag.v = v
        tag.save!
      end
    end
  end

  ##
  # set the auto-close time to be one hour in the future unless
  # that would make it more than 24h long, in which case clip to
  # 24h, as this has been decided is a reasonable time limit.
  def update_closed_at
    if open?
      self.closed_at = if (closed_at - created_at) > (MAX_TIME_OPEN - IDLE_TIMEOUT)
                         created_at + MAX_TIME_OPEN
                       else
                         Time.now.utc + IDLE_TIMEOUT
                       end
    end
  end

  ##
  # update this instance from another instance given and the user who is
  # doing the updating. note that this method is not for updating the
  # bounding box, only the tags of the changeset.
  def update_from(other, user)
    # ensure that only the user who opened the changeset may modify it.
    raise OSM::APIUserChangesetMismatchError unless user.id == user_id

    # can't change a closed changeset
    raise OSM::APIChangesetAlreadyClosedError, self unless open?

    # copy the other's tags
    self.tags = other.tags

    save_with_tags!
  end
end
