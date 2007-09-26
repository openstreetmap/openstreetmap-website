class SearchController < ApplicationController
  # Support searching for nodes, ways, or all
  # Can search by tag k, v, or both (type->k,value->v)
  # Can search by name (k=name,v=....)

  after_filter :compress_output

  def search_all
    do_search(true,true,true)
  end

  def search_ways
    do_search(true,false,false)
  end
  def search_nodes
    do_search(false,true,false)
  end
  def search_relations
    do_search(false,false,true)
  end

  def do_search(do_ways,do_nodes,do_relations)
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
    relations = Array.new

    # Matching for tags table
    cond_way = Array.new
    sql = 'id IN (SELECT id FROM current_way_tags WHERE 1=1'
    if type
      sql += ' AND k=?'
      cond_way += [type]
    end
    if value
      sql += ' AND v=?'
      cond_way += [value]
    end
    sql += ')'
    cond_way = [sql] + cond_way

    # Matching for tags table
    cond_rel = Array.new
    sql = 'id IN (SELECT id FROM current_relation_tags WHERE 1=1'
    if type
      sql += ' AND k=?'
      cond_rel += [type]
    end
    if value
      sql += ' AND v=?'
      cond_rel += [value]
    end
    sql += ')'
    cond_rel = [sql] + cond_rel

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

    # First up, look for the relations we want
    if do_relations
      relations = Relation.find(:all, :conditions => cond_rel, :limit => 100)
    end

    # then ways
    if do_ways
      ways = Way.find(:all, :conditions => cond_way, :limit => 100)
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

    relations.each do |rel|
      doc.root << rel.to_xml_node(user_display_name_cache)
    end 
    render :text => doc.to_s, :content_type => "text/xml"
  end
end
