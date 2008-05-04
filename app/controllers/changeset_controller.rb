# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize, :only => [:create, :update, :delete, :upload]
  before_filter :check_write_availability, :only => [:create, :update, :delete, :upload]
  before_filter :check_read_availability, :except => [:create, :update, :delete, :upload]
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

  def create_prim(ids, prim, nd)
    prim.version = 0
    prim.user_id = @user.id
    prim.visible = true
    prim.save_with_history!

    ids[nd['id'].to_i] = prim.id
  end

  def fix_way(w, node_ids)
    w.nds = w.instance_eval { @nds }.
      map { |nd| node_ids[nd] || nd }
    return w
  end

  def fix_rel(r, ids)
    r.members = r.instance_eval { @members }.
      map { |memb| [memb[0], ids[memb[0]][memb[1].to_i] || memb[1], memb[2]] }
    return r
  end

  def upload
    if not request.put?
      render :nothing => true, :status => :method_not_allowed
      return
    end

    # FIXME: this should really be done without loading the whole XML file
    # into memory.
    p = XML::Parser.new
    p.string  = request.raw_post
    doc = p.parse

    node_ids, way_ids, rel_ids = {}, {}, {}
    ids = {"node"=>node_ids, "way"=>way_ids, "relation"=>rel_ids}

    Changeset.transaction do
      doc.find('//osm/create/node').each do |nd|
	create_prim node_ids, Node.from_xml_node(nd, true), nd
      end
      doc.find('//osm/create/way').each do |nd|
	way = Way.from_xml_node(nd, true)
	fix_way(way, node_ids)
	raise OSM::APIPreconditionFailedError.new if !way.preconditions_ok?
	create_prim way_ids, way, nd
      end
      doc.find('//osm/create/relation').each do |nd|
	relation = Relation.from_xml_node(nd, true)
	fix_rel(relation, ids)
	raise OSM::APIPreconditionFailedError.new if !relation.preconditions_ok?
	create_prim rel_ids, relation, nd
      end

      doc.find('//osm/modify/relation').each do |nd|
	new_relation = Relation.from_xml_node(nd)
	Relation.find(new_relation.id).update_from new_relation, @user
      end
      doc.find('//osm/modify/way').each do |nd|
	new_way = Way.from_xml_node(nd)
	Way.find(new_way.id).update_from new_way, @user
      end
      doc.find('//osm/modify/node').each do |nd|
	new_node = Node.from_xml_node(nd)
	Node.find(new_node.id).update_from new_node, @user
      end

      doc.find('//osm/delete/relation').each do |nd|
	Relation.find(nd['id']).delete_with_history(@user)
      end
      doc.find('//osm/delete/way').each do |nd|
	Way.find(nd['id']).delete_with_relations_and_history(@user)
      end
      doc.find('//osm/delete/node').each do |nd|
	Node.find(nd['id']).delete_with_history(@user)
      end
    end

    render :text => "Ok, Fine. Upload worked without errors.\n", :status => 200
  end
end
