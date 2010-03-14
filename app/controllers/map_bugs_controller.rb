class MapBugsController < ApplicationController

  before_filter :check_api_readable
  before_filter :authorize_web, :only => [:add_bug, :close_bug, :edit_bug, :delete]
  before_filter :check_api_writable, :only => [:add_bug, :close_bug, :edit_bug, :delete]
  before_filter :require_moderator, :only => [:delete]
  after_filter :compress_output
  around_filter :api_call_handle_error, :api_call_timeout

  # Help methods for checking boundary sanity and area size
  include MapBoundary

  def get_bugs

	# Figure out the bbox
    bbox = params['bbox']

    if bbox and bbox.count(',') == 3
      bbox = bbox.split(',')
	  min_lon, min_lat, max_lon, max_lat = sanitise_boundaries(bbox)
	else
	  #Fallback to old style, this is deprecated and should not be used
	  raise OSM::APIBadUserInput.new("No l was given") unless params['l']
	  raise OSM::APIBadUserInput.new("No r was given") unless params['r']
	  raise OSM::APIBadUserInput.new("No b was given") unless params['b']
	  raise OSM::APIBadUserInput.new("No t was given") unless params['t']

	  min_lon = params['l'].to_f
	  max_lon = params['r'].to_f
	  min_lat = params['b'].to_f
	  max_lat = params['t'].to_f
    end
	limit = getLimit
	conditions = closedCondition
	
	# check boundary is sane and area within defined
    # see /config/application.yml
    begin
      check_boundaries(min_lon, min_lat, max_lon, max_lat)
    rescue Exception => err
      report_error(err.message)
      return
    end



	@bugs = MapBug.find_by_area(min_lat, min_lon, max_lat, max_lon, :order => "last_changed DESC", :limit => limit, :conditions => conditions)

	respond_to do |format|
	  format.html {render :template => 'map_bugs/get_bugs.js', :content_type => "text/javascript"}
	  format.rss {render :template => 'map_bugs/get_bugs.rss'}
	  format.js
	  format.xml {render :template => 'map_bugs/get_bugs.xml'}
	  format.json { render :json => @bugs.to_json(:methods => [:lat, :lon], :only => [:id, :status, :date_created], :include => { :map_bug_comment => { :only => [:commenter_name, :date_created, :comment]}}) }	  
#	  format.gpx {render :template => 'map_bugs/get_bugs.gpx'}
	end
  end

  def add_bug
	raise OSM::APIBadUserInput.new("No lat was given") unless params['lat']
	raise OSM::APIBadUserInput.new("No lon was given") unless params['lon']
	raise OSM::APIBadUserInput.new("No text was given") unless params['text']

	lon = params['lon'].to_f
	lat = params['lat'].to_f
	comment = params['text']

	name = "NoName";
	name = params['name'] if params['name'];

    @bug = MapBug.create_bug(lat, lon)
	@bug.save;
	add_comment(@bug, comment, name);
 
	render_ok
  end

  def edit_bug
	raise OSM::APIBadUserInput.new("No id was given") unless params['id']
	raise OSM::APIBadUserInput.new("No text was given") unless params['text']

	name = "NoName";
	name = params['name'] if params['name'];
	
	id = params['id'].to_i

	bug = MapBug.find_by_id(id);

	bug_comment = add_comment(bug, params['text'], name);

	render_ok
  end

  def close_bug
	raise OSM::APIBadUserInput.new("No id was given") unless params['id']
	
	id = params['id'].to_i

	bug = MapBug.find_by_id(id);
	bug.close_bug;

	render_ok
  end 


  def rss
	request.format = :rss
	get_bugs
  end

  def gpx_bugs
	request.format = :xml
	get_bugs
  end

  def read
	@bug = MapBug.find(params['id'])
    render :text => "", :status => :gone unless @bug.visible
	respond_to do |format|
	  format.rss
	  format.xml
	  format.json { render :json => @bug.to_json(:methods => [:lat, :lon], :only => [:id, :status, :date_created], :include => { :map_bug_comment => { :only => [:commenter_name, :date_created, :comment]}}) }	  
	end
  end

  def delete
	bug = MapBug.find(params['id'])
	bug.status = "hidden"
	bug.save
	render :text => "ok\n", :content_type => "text/html" 
  end

  def search
	raise OSM::APIBadUserInput.new("No query string was given") unless params['q']
	limit = getLimit
	conditions = closedCondition
	
	#TODO: There should be a better way to do this.   CloseConditions are ignored at the moment

	bugs2 = MapBug.find(:all, :limit => limit, :order => "last_changed DESC", :joins => :map_bug_comment,
						:conditions => ['map_bug_comment.comment ~ ?', params['q']])
	@bugs = bugs2.uniq
	respond_to do |format|
	  format.html {render :template => 'map_bugs/get_bugs.js', :content_type => "text/javascript"}
	  format.rss {render :template => 'map_bugs/get_bugs.rss'}
	  format.js
	  format.xml {render :template => 'map_bugs/get_bugs.xml'}
	  format.json { render :json => @bugs.to_json(:methods => [:lat, :lon], :only => [:id, :status, :date_created], :include => { :map_bug_comment => { :only => [:commenter_name, :date_created, :comment]}}) }
#	  format.gpx {render :template => 'map_bugs/get_bugs.gpx'}
	end
  end


  def render_ok
	output_js = :false
	output_js = :true if params['format'] == "js"

	if output_js == :true
	  render :text => "osbResponse();", :content_type => "text/javascript" 
	else
	  render :text => "ok " + @bug.id.to_s + "\n", :content_type => "text/html" if @bug
	  render :text => "ok\n", :content_type => "text/html" unless @bug
	end
  end

  def getLimit
	limit = 100;
	limit = params['limit'] if ((params['limit']) && (params['limit'].to_i < 10000) && (params['limit'].to_i > 0))
	return limit
  end

  def closedCondition
	closed_since = 7 unless params['closed']
	closed_since = params['closed'].to_i if params['closed']
	
	if closed_since < 0
	  conditions = "status != 'hidden'"
	elsif closed_since > 0
	  conditions = "((status = 'open') OR ((status = 'closed' ) AND (date_closed > '" + (Time.now - 7.days).to_s + "')))"
	else
	  conditions = "status = 'open'"
	end

	return conditions
  end

  def add_comment(bug, comment, name) 
    t = Time.now.getutc 
    bug_comment = bug.map_bug_comment.create(:date_created => t, :visible => true, :comment => comment);  
    if @user  
      bug_comment.commenter_id = @user.id
	  bug_comment.commenter_name = @user.display_name
    else  
      bug_comment.commenter_ip = request.remote_ip
	  bug_comment.commenter_name = name + " (a)"
    end
    bug_comment.save; 
    bug.last_changed = t 
    bug.save 
  end

end
