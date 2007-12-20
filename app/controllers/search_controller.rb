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
    sql = '1=1'
    if type
      sql += ' AND current_way_tags.k=?'
      cond_way += [type]
    end
    if value
      sql += ' AND current_way_tags.v=? AND MATCH (current_way_tags.v) AGAINST (? IN BOOLEAN MODE)'
      cond_way += [value,'"' + value.sub(/[-+*<>"~()]/, ' ') + '"']
    end
    cond_way = [sql] + cond_way

    # Matching for tags table
    cond_rel = Array.new
    sql = '1=1'
    if type
      sql += ' AND current_relation_tags.k=?'
      cond_rel += [type]
    end
    if value
      sql += ' AND current_relation_tags.v=? AND MATCH (current_relation_tags.v) AGAINST (? IN BOOLEAN MODE)'
      cond_rel += [value,'"' + value.sub(/[-+*<>"~()]/, ' ') + '"']
    end
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
      relations = Relation.find(:all,
                                :joins => "INNER JOIN current_relation_tags ON current_relation_tags.id = current_relations.id",
                                :conditions => cond_rel, :limit => 100)
    end

    # then ways
    if do_ways
      ways = Way.find(:all,
                      :joins => "INNER JOIN current_way_tags ON current_way_tags.id = current_ways.id",
                      :conditions => cond_way, :limit => 100)
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
