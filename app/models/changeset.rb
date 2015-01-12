class Changeset < ActiveRecord::Base
  require 'xml/libxml'

  belongs_to :user, :counter_cache => true

  has_many :changeset_tags

  has_many :nodes
  has_many :ways
  has_many :relations
  has_many :old_nodes
  has_many :old_ways
  has_many :old_relations
  
  has_many :comments, -> { where(:visible => true).order(:created_at) }, :class_name => "ChangesetComment"
  has_and_belongs_to_many :subscribers, :class_name => 'User', :join_table => 'changesets_subscribers', :association_foreign_key => 'subscriber_id'

  validates_presence_of :id, :on => :update
  validates_presence_of :user_id, :created_at, :closed_at, :num_changes
  validates_uniqueness_of :id
  validates_numericality_of :id, :on => :update, :integer_only => true
  validates_numericality_of :min_lat, :max_lat, :min_lon, :max_lat, :allow_nil => true, :integer_only => true
  validates_numericality_of :user_id,  :integer_only => true
  validates_numericality_of :num_changes, :integer_only => true, :greater_than_or_equal_to => 0

  before_save :update_closed_at

  # over-expansion factor to use when updating the bounding box
  EXPAND = 0.1

  # maximum number of elements allowed in a changeset
  MAX_ELEMENTS = 50000

  # maximum time a changeset is allowed to be open for.
  MAX_TIME_OPEN = 1.day

  # idle timeout increment, one hour seems reasonable.
  IDLE_TIMEOUT = 1.hour

  # Use a method like this, so that we can easily change how we
  # determine whether a changeset is open, without breaking code in at
  # least 6 controllers
  def is_open?
    # a changeset is open (that is, it will accept further changes) when
    # it has not yet run out of time and its capacity is small enough.
    # note that this may not be a hard limit - due to timing changes and
    # concurrency it is possible that some changesets may be slightly
    # longer than strictly allowed or have slightly more changes in them.
    return ((closed_at > Time.now.getutc) and (num_changes <= MAX_ELEMENTS))
  end

  def set_closed_time_now
    if is_open?
      self.closed_at = Time.now.getutc
    end
  end

  def self.from_xml(xml, create=false)
    begin
      p = XML::Parser.string(xml, :options => XML::Parser::Options::NOERROR)
      doc = p.parse

      doc.find('//osm/changeset').each do |pt|
        return Changeset.from_xml_node(pt, create)
      end
      raise OSM::APIBadXMLError.new("changeset", xml, "XML doesn't contain an osm/changeset element.")
    rescue LibXML::XML::Error, ArgumentError => ex
      raise OSM::APIBadXMLError.new("changeset", xml, ex.message)
    end
  end

  def self.from_xml_node(pt, create=false)
    cs = Changeset.new
    if create
      cs.created_at = Time.now.getutc
      # initial close time is 1h ahead, but will be increased on each
      # modification.
      cs.closed_at = cs.created_at + IDLE_TIMEOUT
      # initially we have no changes in a changeset
      cs.num_changes = 0
    end

    pt.find('tag').each do |tag|
      raise OSM::APIBadXMLError.new("changeset", pt, "tag is missing key") if tag['k'].nil?
      raise OSM::APIBadXMLError.new("changeset", pt, "tag is missing value") if tag['v'].nil?
      cs.add_tag_keyval(tag['k'], tag['v'])
    end

    return cs
  end

  ##
  # returns the bounding box of the changeset. it is possible that some
  # or all of the values will be nil, indicating that they are undefined.
  def bbox
    @bbox ||= BoundingBox.new(min_lon, min_lat, max_lon, max_lat)
  end

  def has_valid_bbox?
    bbox.complete?
  end

  ##
  # expand the bounding box to include the given bounding box. also,
  # expand a little bit more in the direction of the expansion, so that
  # further expansions may be unnecessary. this is an optimisation
  # suggested on the wiki page by kleptog.
  def update_bbox!(bbox_update)
    bbox.expand!(bbox_update, EXPAND)
      
    # update active record. rails 2.1's dirty handling should take care of
    # whether this object needs saving or not.
    self.min_lon, self.min_lat, self.max_lon, self.max_lat = @bbox.to_a if bbox.complete?
  end

  ##
  # the number of elements is also passed in so that we can ensure that
  # a single changeset doesn't contain too many elements. this, of course,
  # destroys the optimisation described in the bbox method above.
  def add_changes!(elements)
    self.num_changes += elements
  end

  def tags_as_hash
    return tags
  end

  def tags
    unless @tags
      @tags = {}
      self.changeset_tags.each do |tag|
        @tags[tag.k] = tag.v
      end
    end
    @tags
  end

  def tags=(t)
    @tags = t
  end

  def add_tag_keyval(k, v)
    @tags = Hash.new unless @tags

    # duplicate tags are now forbidden, so we can't allow values
    # in the hash to be overwritten.
    raise OSM::APIDuplicateTagsError.new("changeset", self.id, k) if @tags.include? k

    @tags[k] = v
  end

  def save_with_tags!
    # do the changeset update and the changeset tags update in the
    # same transaction to ensure consistency.
    Changeset.transaction do
      self.save!

      tags = self.tags
      ChangesetTag.delete_all(:changeset_id => self.id)

      tags.each do |k,v|
        tag = ChangesetTag.new
        tag.changeset_id = self.id
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
    if self.is_open?
      if (closed_at - created_at) > (MAX_TIME_OPEN - IDLE_TIMEOUT)
        self.closed_at = created_at + MAX_TIME_OPEN
      else
        self.closed_at = Time.now.getutc + IDLE_TIMEOUT
      end
    end
  end

  def to_xml(include_discussion = false)
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node(nil, include_discussion)
    return doc
  end

  def to_xml_node(user_display_name_cache = nil, include_discussion = false)
    el1 = XML::Node.new 'changeset'
    el1['id'] = self.id.to_s

    user_display_name_cache = {} if user_display_name_cache.nil?

    if user_display_name_cache and user_display_name_cache.key?(self.user_id)
      # use the cache if available
    elsif self.user.data_public?
      user_display_name_cache[self.user_id] = self.user.display_name
    else
      user_display_name_cache[self.user_id] = nil
    end

    el1['user'] = user_display_name_cache[self.user_id] unless user_display_name_cache[self.user_id].nil?
    el1['uid'] = self.user_id.to_s if self.user.data_public?

    self.tags.each do |k,v|
      el2 = XML::Node.new('tag')
      el2['k'] = k.to_s
      el2['v'] = v.to_s
      el1 << el2
    end

    el1['created_at'] = self.created_at.xmlschema
    el1['closed_at'] = self.closed_at.xmlschema unless is_open?
    el1['open'] = is_open?.to_s

    if bbox.complete?
      bbox.to_unscaled.add_bounds_to(el1, '_')
    end

    el1['comments_count'] = self.comments.count.to_s

    if include_discussion
      el2 = XML::Node.new('discussion')
      self.comments.includes(:author).each do |comment|
        el3 = XML::Node.new('comment')
        el3['date'] = comment.created_at.xmlschema
        el3['uid'] = comment.author.id.to_s if comment.author.data_public?
        el3['user'] = comment.author.display_name.to_s if comment.author.data_public?
        el4 = XML::Node.new('text')
        el4.content = comment.body.to_s
        el3 << el4
        el2 << el3
      end
      el1 << el2
    end

    # NOTE: changesets don't include the XML of the changes within them,
    # they are just structures for tagging. to get the osmChange of a
    # changeset, see the download method of the controller.

    return el1
  end

  ##
  # update this instance from another instance given and the user who is
  # doing the updating. note that this method is not for updating the
  # bounding box, only the tags of the changeset.
  def update_from(other, user)
    # ensure that only the user who opened the changeset may modify it.
    unless user.id == self.user_id
      raise OSM::APIUserChangesetMismatchError.new
    end

    # can't change a closed changeset
    unless is_open?
      raise OSM::APIChangesetAlreadyClosedError.new(self)
    end

    # copy the other's tags
    self.tags = other.tags

    save_with_tags!
  end
end
