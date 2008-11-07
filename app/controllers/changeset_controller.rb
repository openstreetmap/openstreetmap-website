# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetController < ApplicationController
  require 'xml/libxml'
  require 'diff_reader'

  before_filter :authorize, :only => [:create, :update, :delete, :upload, :include]
  before_filter :check_write_availability, :only => [:create, :update, :delete, :upload, :include]
  before_filter :check_read_availability, :except => [:create, :update, :delete, :upload, :download]
  after_filter :compress_output

  # Create a changeset from XML.
  def create
    if request.put?
      cs = Changeset.from_xml(request.raw_post, true)

      if cs
        cs.user_id = @user.id
        cs.save_with_tags!
        render :text => cs.id.to_s, :content_type => "text/plain"
      else
        render :nothing => true, :status => :bad_request
      end
    else
      render :nothing => true, :status => :method_not_allowed
    end
  end

  def read
    begin
      changeset = Changeset.find(params[:id])
      render :text => changeset.to_xml.to_s, :content_type => "text/xml"
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end
  
  def close 
    begin
      unless request.put?
        render :nothing => true, :status => :method_not_allowed
        return
      end

      changeset = Changeset.find(params[:id])

      unless @user.id == changeset.user_id 
        raise OSM::APIUserChangesetMismatchError 
      end

      changeset.open = false
      changeset.save!
      render :nothing => true
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end

  ##
  # insert a (set of) points into a changeset bounding box. this can only
  # increase the size of the bounding box. this is a hint that clients can
  # set either before uploading a large number of changes, or changes that
  # the client (but not the server) knows will affect areas further away.
  def include
    # only allow POST requests, because although this method is
    # idempotent, there is no "document" to PUT really...
    if request.post?
      cs = Changeset.find(params[:id])

      # check user credentials - only the user who opened a changeset
      # may alter it.
      unless @user.id == cs.user_id 
        raise OSM::APIUserChangesetMismatchError 
      end

      # keep an array of lons and lats
      lon = Array.new
      lat = Array.new

      # the request is in pseudo-osm format... this is kind-of an
      # abuse, maybe should change to some other format?
      doc = XML::Parser.string(request.raw_post).parse
      doc.find("//osm/node").each do |n|
        lon << n['lon'].to_f * SCALE
        lat << n['lat'].to_f * SCALE
      end

      # add the existing bounding box to the lon-lat array
      lon << cs.min_lon unless cs.min_lon.nil?
      lat << cs.min_lat unless cs.min_lat.nil?
      lon << cs.max_lon unless cs.max_lon.nil?
      lat << cs.max_lat unless cs.max_lat.nil?

      # collapse the arrays to minimum and maximum
      cs.min_lon, cs.min_lat, cs.max_lon, cs.max_lat = 
        lon.min, lat.min, lon.max, lat.max

      # save the larger bounding box and return the changeset, which
      # will include the bigger bounding box.
      cs.save!
      render :text => cs.to_xml.to_s, :content_type => "text/xml"

    else
      render :nothing => true, :status => :method_not_allowed
    end

  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  rescue OSM::APIError => ex
    render ex.render_opts
  end

  ##
  # Upload a diff in a single transaction.
  #
  # This means that each change within the diff must succeed, i.e: that
  # each version number mentioned is still current. Otherwise the entire
  # transaction *must* be rolled back.
  #
  # Furthermore, each element in the diff can only reference the current
  # changeset.
  #
  # Returns: a diffResult document, as described in 
  # http://wiki.openstreetmap.org/index.php/OSM_Protocol_Version_0.6
  def upload
    # only allow POST requests, as the upload method is most definitely
    # not idempotent, as several uploads with placeholder IDs will have
    # different side-effects.
    # see http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.1.2
    unless request.post?
      render :nothing => true, :status => :method_not_allowed
      return
    end

    changeset = Changeset.find(params[:id])

    # access control - only the user who created a changeset may
    # upload to it.
    unless @user.id == changeset.user_id 
      raise OSM::APIUserChangesetMismatchError 
    end
    
    diff_reader = DiffReader.new(request.raw_post, changeset)
    Changeset.transaction do
      result = diff_reader.commit
      render :text => result.to_s, :content_type => "text/xml"
    end
    
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  rescue OSM::APIError => ex
    render ex.render_opts
  end

  ##
  # download the changeset as an osmChange document.
  #
  # to make it easier to revert diffs it would be better if the osmChange
  # format were reversible, i.e: contained both old and new versions of 
  # modified elements. but it doesn't at the moment...
  #
  # this method cannot order the database changes fully (i.e: timestamp and
  # version number may be too coarse) so the resulting diff may not apply
  # to a different database. however since changesets are not atomic this 
  # behaviour cannot be guaranteed anyway and is the result of a design
  # choice.
  def download
    changeset = Changeset.find(params[:id])
    
    # get all the elements in the changeset and stick them in a big array.
    elements = [changeset.old_nodes, 
                changeset.old_ways, 
                changeset.old_relations].flatten
    
    # sort the elements by timestamp and version number, as this is the 
    # almost sensible ordering available. this would be much nicer if 
    # global (SVN-style) versioning were used - then that would be 
    # unambiguous.
    elements.sort! do |a, b| 
      if (a.timestamp == b.timestamp)
        a.version <=> b.version
      else
        a.timestamp <=> b.timestamp 
      end
    end
    
    # create an osmChange document for the output
    result = OSM::API.new.get_xml_doc
    result.root.name = "osmChange"

    # generate an output element for each operation. note: we avoid looking
    # at the history because it is simpler - but it would be more correct to 
    # check these assertions.
    elements.each do |elt|
      result.root <<
        if (elt.version == 1) 
          # first version, so it must be newly-created.
          created = XML::Node.new "create"
          created << elt.to_xml_node
        else
          # get the previous version from the element history
          prev_elt = elt.class.find(:first, :conditions => 
                                    ['id = ? and version = ?',
                                     elt.id, elt.version])
          unless elt.visible
            # if the element isn't visible then it must have been deleted, so
            # output the *previous* XML
            deleted = XML::Node.new "delete"
            deleted << prev_elt.to_xml_node
          else
            # must be a modify, for which we don't need the previous version
            # yet...
            modified = XML::Node.new "modify"
            modified << elt.to_xml_node
          end
        end
    end

    render :text => result.to_s, :content_type => "text/xml"
            
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  rescue OSM::APIError => ex
    render ex.render_opts
  end

end
