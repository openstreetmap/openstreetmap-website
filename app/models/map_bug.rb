class MapBug < ActiveRecord::Base
  include GeoRecord

  set_table_name 'map_bugs'

  validates_presence_of :id, :on => :update
  validates_uniqueness_of :id
  validates_numericality_of :latitude, :only_integer => true
  validates_numericality_of :longitude, :only_integer => true
  validates_presence_of :date_created
  validates_presence_of :last_changed
  validates_prensence_of :date_closed if :status == "closed"
  validates_inclusion_of :status, :in => [ "open", "closed", "hidden" ]

  has_many :map_bug_comment, :foreign_key => :bug_id, :order => :date_created, :conditions => "visible = true and comment is not null"


  def self.create_bug(lat, lon)
	bug = MapBug.new(:lat => lat, :lon => lon);
	raise OSM::APIBadUserInput.new("The node is outside this world") unless bug.in_world?
	bug.date_created = Time.now.getutc
	bug.last_changed = Time.now.getutc
	bug.status = "open";
	return bug;
  end

  def close_bug
	self.status = "closed"
	close_time = Time.now.getutc
	self.last_changed = close_time
	self.date_closed = close_time

	self.save;
  end

  def flatten_comment ( separator_char, upto_timestamp = :nil)
	resp = ""
	comment_no = 1
	self.map_bug_comment.each do |comment|
	  next if upto_timestamp != :nil and comment.date_created > upto_timestamp
        resp += (comment_no == 1 ? "" : separator_char)
		resp += comment.comment if comment.comment
		resp += " [ " 
		resp += comment.commenter_name if comment.commenter_name
		resp += " " + comment.date_created.to_s + " ]"
		comment_no += 1
	end

	return resp

  end

  def visible
	return status != "hidden"
  end

end
