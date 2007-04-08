class SearchController < ApplicationController
  # Support searching for nodes, segments, ways, or all
  # Can search by tag k, v, or both (type->k,value->v)
  # Can search by name (k=name,v=....)

  before_filter :authorize
  after_filter :compress_output

  def search_all
    do_search(true,true,true)
  end

  def search_ways
    do_search(true,false,false)
  end
  def search_segments
    do_search(false,true,false)
  end
  def search_nodes
    do_search(false,false,true)
  end


  def do_search(do_ways,do_segments,do_nodes)
    response.headers["Content-Type"] = 'application/xml'

    type = params['type']
    value = params['value']
	unless type or value
		name = params['name']
		if name
			type = 'name'
			value = name
		end
	end

    way_ids = Array.new
    ways = Array.new
    segments = Array.new
    nodes = Array.new

    # Matching for tags table
    cond_tbl = Array.new
    sql = '1=1'
    if type
	   sql += ' AND k=?'
	   cond_tbl += [type]
    end
    if value
	   sql += ' AND v=?'
	   cond_tbl += [value]
    end
    cond_tbl = [sql] + cond_tbl

    # Matching for tags column
    if type and value
       cond_tags = ['tags LIKE ? OR tags LIKE ? OR tags LIKE ? OR tags LIKE ?', 
                      ''+type+'='+value+'',
                      ''+type+'='+value+';%',
                      '%;'+type+'='+value+';%',
                      '%;'+type+'='+value+'' ]
	elsif type
       cond_tags = ['tags LIKE ? OR tags LIKE ?',
                      ''+type+'=%',
                      '%;'+type+'=%' ]
	elsif value
       cond_tags = ['tags LIKE ? OR tags LIKE ?',
                      '%='+value+';%',
                      '%='+value+'' ]
    else
       cond_tags = ['1=1']
    end
    

	# First up, look for the ids of the ways we want
	if do_ways
       ways_tmp = WayTag.find(:all, :conditions => cond_tbl)
       way_ids = ways_tmp.collect {|way| way.id }
    end

    # Now, segments matching
	if do_segments
       segs = Segment.find(:all, :conditions => cond_tags)
    end

    # Now, nodes
	if do_nodes
       nodes = Node.find(:all, :conditions => cond_tags)
    end

    # Get the remaining objects:
    # Fetch the ways (until now only had their ids)
    ways = Way.find(way_ids)

    # Fetch any segments needed for our ways (only have matching segments so far)
	seg_ids = Array.new
    ways.each do |way|
	    seg_ids += way.segments
    end
    segments += Segment.find(seg_ids)

    # Fetch any nodes needed for our segments (only have matching nodes so far)
    node_ids = Array.new
    segments.each do |seg|
        node_ids += seg.node_a
        node_ids += seg.node_b
    end
    nodes += Node.find(node_ids)


	# Print
    doc = OSM::API.get_xml_doc
    nodes.each do |node|
      doc.root << node.to_xml_node()
    end

    segments.each do |segment|
      doc.root << segment.to_xml_node()
    end 

    ways.each do |way|
      doc.root << way.to_xml_node()
    end 

    render :text => doc.to_s
  end
end
