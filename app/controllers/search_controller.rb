class SearchController < ApplicationController
  # Support searching for nodes, ways, or all
  # Can search by tag k, v, or both (type->k,value->v)
  # Can search by name (k=name,v=....)
  skip_before_filter :verify_authenticity_token
  after_filter :compress_output

  def search_all
    do_search(true, true, true)
  end

  def search_ways
    do_search(true, false, false)
  end

  def search_nodes
    do_search(false, true, false)
  end

  def search_relations
    do_search(false, false, true)
  end

  def do_search(do_ways, do_nodes, do_relations)
    type = params['type']
    value = params['value']
    unless type || value
      name = params['name']
      if name
        type = 'name'
        value = name
      end
    end

    if do_nodes
      response.headers['Error'] = "Searching of nodes is currently unavailable"
      render :text => "", :status => :service_unavailable
      return false
    end

    unless value
      response.headers['Error'] = "Searching for a key without value is currently unavailable"
      render :text => "", :status => :service_unavailable
      return false
    end

    # Matching for node tags table
    if do_nodes
      nodes = Node.joins(:node_tags)
      nodes = nodes.where(:current_node_tags => { :k => type }) if type
      nodes = nodes.where(:current_node_tags => { :v => value }) if value
      nodes = nodes.limit(100)
    else
      nodes = []
    end

    # Matching for way tags table
    if do_ways
      ways = Way.joins(:way_tags)
      ways = ways.where(:current_way_tags => { :k => type }) if type
      ways = ways.where(:current_way_tags => { :v => value }) if value
      ways = ways.limit(100)
    else
      ways = []
    end

    # Matching for relation tags table
    if do_relations
      relations = Relation.joins(:relation_tags)
      relations = relations.where(:current_relation_tags => { :k => type }) if type
      relations = relations.where(:current_relation_tags => { :v => value }) if value
      relations = relations.limit(2000)
    else
      relations = []
    end

    # Fetch any node needed for our ways (only have matching nodes so far)
    nodes += Node.find(ways.collect(&:nds).uniq)

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
      doc.root << rel.to_xml_node(nil, changeset_cache, user_display_name_cache)
    end

    render :text => doc.to_s, :content_type => "text/xml"
  end
end
