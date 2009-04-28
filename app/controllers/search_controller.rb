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

    if do_nodes
      response.headers['Error'] = "Searching of nodes is currently unavailable"
      render :nothing => true, :status => :service_unavailable
      return false
    end

    unless value
      response.headers['Error'] = "Searching for a key without value is currently unavailable"
      render :nothing => true, :status => :service_unavailable
      return false
    end

    way_ids = Array.new
    ways = Array.new
    nodes = Array.new
    relations = Array.new

    # Matching for node tags table
    cond_node = Array.new
    sql = '1=1'
    if type
      sql += ' AND current_node_tags.k=?'
      cond_node += [type]
    end
    if value
      sql += ' AND current_node_tags.v=?'
      cond_node += [value]
    end
    cond_node = [sql] + cond_node

    # Matching for way tags table
    cond_way = Array.new
    sql = '1=1'
    if type
      sql += ' AND current_way_tags.k=?'
      cond_way += [type]
    end
    if value
      sql += ' AND current_way_tags.v=?'
      cond_way += [value]
    end
    cond_way = [sql] + cond_way

    # Matching for relation tags table
    cond_rel = Array.new
    sql = '1=1'
    if type
      sql += ' AND current_relation_tags.k=?'
      cond_rel += [type]
    end
    if value
      sql += ' AND current_relation_tags.v=?'
      cond_rel += [value]
    end
    cond_rel = [sql] + cond_rel

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
      nodes = Node.find(:all,
                        :joins => "INNER JOIN current_node_tags ON current_node_tags.id = current_nodes.id",
                        :conditions => cond_node, :limit => 2000)
    end

    # Fetch any node needed for our ways (only have matching nodes so far)
    nodes += Node.find(ways.collect { |w| w.nds }.uniq)

    # Print
    visible_nodes = {}
    changeset_cache = {}
    user_display_name_cache = {}
    doc = OSM::API.new.get_xml_doc
    nodes.each do |node|
      doc.root << node.to_xml_node(changeset_cache, user_display_name_cache)
      visible_nodes[node.id] = node
    end

    ways.each do |way|
      doc.root << way.to_xml_node(visible_nodes, changeset_cache, user_display_name_cache)
    end 

    relations.each do |rel|
      doc.root << rel.to_xml_node(changeset_cache, user_display_name_cache)
    end 
    render :text => doc.to_s, :content_type => "text/xml"
  end
end
