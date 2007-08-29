class SearchController < ApplicationController
  # Support searching for nodes, ways, or all
  # Can search by tag k, v, or both (type->k,value->v)
  # Can search by name (k=name,v=....)

  after_filter :compress_output

  def search_all
    do_search(true,true)
  end

  def search_ways
    do_search(true,false)
  end
  def search_nodes
    do_search(false,true)
  end


  def do_search(do_ways,do_nodes)
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

    # Now, nodes
    if do_nodes
      nodes = Node.find(:all, :conditions => cond_tags, :limit => 2000)
    end

    # Fetch any node needed for our ways (only have matching nodes so far)
    nodes += Node.find(ways.collect { |w| w.nds }.uniq)

    # Print
    user_display_name_cache = {}
    doc = OSM::API.new.get_xml_doc
    nodes.each do |node|
      doc.root << node.to_xml_node(user_display_name_cache)
    end

    ways.each do |way|
      doc.root << way.to_xml_node(user_display_name_cache)
    end 

    render :text => doc.to_s, :content_type => "text/xml"
  end
end
