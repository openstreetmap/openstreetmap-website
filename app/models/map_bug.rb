class MapBug < ActiveRecord::Base
  include GeoRecord

  has_many :comments, :class_name => "MapBugComment",
                      :foreign_key => :bug_id,
                      :order => :created_at,
                      :conditions => "visible = true AND body IS NOT NULL"

  validates_presence_of :id, :on => :update
  validates_uniqueness_of :id
  validates_numericality_of :latitude, :only_integer => true
  validates_numericality_of :longitude, :only_integer => true
  validates_presence_of :closed_at if :status == "closed"
  validates_inclusion_of :status, :in => ["open", "closed", "hidden"]

  def self.create_bug(lat, lon)
    bug = MapBug.new(:lat => lat, :lon => lon, :status => "open")
    raise OSM::APIBadUserInput.new("The node is outside this world") unless bug.in_world?

    return bug
  end

  def close_bug
    self.status = "closed"
    self.closed_at = Time.now.getutc

    self.save
  end

  def flatten_comment(separator_char, upto_timestamp = :nil)
    resp = ""
    comment_no = 1
    self.comments.each do |comment|
      next if upto_timestamp != :nil and comment.created_at > upto_timestamp
      resp += (comment_no == 1 ? "" : separator_char)
      resp += comment.body if comment.body
      resp += " [ " 
      resp += comment.author_name if comment.author_name
      resp += " " + comment.created_at.to_s + " ]"
      comment_no += 1
    end

    return resp
  end

  def visible
    return status != "hidden"
  end
end
