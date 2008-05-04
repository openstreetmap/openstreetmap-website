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
    w.nds.each { |nd|
      new_id = node_ids[nd.node_id]
      nd.node_id = new_id unless new_id.nil?
    }
  end

  def fix_rel(r, ids)
    r.members.each { |memb|
      new_id = ids[memb.member_type][memb.member_id]
      nd.member_id = new_id unless new_id.nil?
    }
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
	raise OSM::APIPreconditionFailedError.new if !way.preconditions_ok?
	create_prim way_ids, fix_way(way, node_ids), nd
      end
      doc.find('//osm/create/relation').each do |nd|
	relation = Relation.from_xml_node(nd, true)
	raise OSM::APIPreconditionFailedError.new if !way.preconditions_ok?
	create_prim relation_ids, fix_rel(relation, ids), nd
      end

      doc.find('//osm/modify/node').each do |nd|
	unless NodeController.update_internal nil, Node.from_xml_node(nd)
	  raise OSM::APIPreconditionFailedError.new
	end
      end
      doc.find('//osm/modify/way').each do |nd|
	unless WayController.update_internal nil, fix_way(Way.from_xml_node(nd), node_ids)
	  raise OSM::APIPreconditionFailedError.new
	end
      end
      doc.find('//osm/modify/relation').each do |nd|
	unless RelationController.update_internal nil, fix_rel(Relation.from_xml_node(nd), ids)
	  raise OSM::APIPreconditionFailedError.new
	end
      end

      doc.find('//osm/delete/node').each do |nd|
	unless NodeController.delete_internal nil, Node.from_xml_node(n)
	  raise OSM::APIPreconditionFailedError.new
	end
      end
      doc.find('//osm/delete/way').each do |nd|
	Way.from_xml_node(nd).delete_with_relations_and_history(@user)
      end
      doc.find('//osm/delete/relation').each do |nd|
	unless RelationController.delete_internal nil, fix_rel(Relation.from_xml_node(nd), ids)
	  raise OSM::APIPreconditionFailedError.new
	end
      end
    end

    render :text => "Ok, Fine. Upload worked without errors.\n", :status => 200
  end
end
