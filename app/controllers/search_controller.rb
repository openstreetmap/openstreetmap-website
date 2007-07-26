class SearchController < ApplicationController
  # Support searching for nodes, segments, ways, or all
  # Can search by tag k, v, or both (type->k,value->v)
  # Can search by name (k=name,v=....)

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
    sql = 'id IN (SELECT id FROM current_way_tags WHERE 1=1'
    if type
      sql += ' AND k=?'
      cond_tbl += [type]
    end
    if value
      sql += ' AND v=?'
      cond_tbl += [value]
    end
    sql += ')'
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


    # First up, look for the ways we want
    if do_ways
      ways = Way.find(:all, :conditions => cond_tbl, :limit => 100)
    end

    # Now, segments matching
    if do_segments
      segments = Segment.find(:all, :conditions => cond_tags, :limit => 500)
    end

    # Now, nodes
    if do_nodes
      nodes = Node.find(:all, :conditions => cond_tags, :limit => 2000)
    end

    # Fetch any segments needed for our ways (only have matching segments so far)
    segments += Segment.find(ways.collect { |w| w.segs }.uniq)

    # Fetch any nodes needed for our segments (only have matching nodes so far)
    nodes += Node.find(segments.collect { |s| [s.node_a, s.node_b] }.flatten.uniq)

    # Print
    user_display_name_cache = {}
    doc = OSM::API.new.get_xml_doc
    nodes.each do |node|
      doc.root << node.to_xml_node(user_display_name_cache)
    end

    segments.each do |segment|
      doc.root << segment.to_xml_node(user_display_name_cache)
    end 

    ways.each do |way|
      doc.root << way.to_xml_node(user_display_name_cache)
    end 

    render :text => doc.to_s, :content_type => "text/xml"
  end
end
