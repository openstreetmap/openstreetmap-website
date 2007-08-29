class RelationController < ApplicationController
  require 'xml/libxml'

  before_filter :authorize, :only => [:create, :update, :delete]
  before_filter :check_availability, :only => [:create, :update, :delete]

  after_filter :compress_output

  def create
    if request.put?
      relation = Relation.from_xml(request.raw_post, true)

      if relation
        if !relation.preconditions_ok?
          render :nothing => true, :status => :precondition_failed
        else
          relation.user_id = @user.id

          if relation.save_with_history
            render :text => relation.id.to_s, :content_type => "text/plain"
          else
            render :text => "save error", :status => :internal_server_error
          end
        end
      else
        render :nothing => true, :status => :bad_request
      end
    else
      render :nothing => true, :status => :method_not_allowed
    end
  end

  def read
    begin
      relation = Relation.find(params[:id])

      if relation.visible
        render :text => relation.to_xml.to_s, :content_type => "text/xml"
      else
        render :nothing => true, :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

  def update
    begin
      relation = Relation.find(params[:id])

      if relation.visible
        new_relation = Relation.from_xml(request.raw_post)

        if new_relation and new_relation.id == relation.id
          if !new_relation.preconditions_ok?
            render :nothing => true, :status => :precondition_failed
          else
            relation.user_id = @user.id
            relation.tags = new_relation.tags
            relation.members = new_relation.members
            relation.visible = true

            if relation.save_with_history
              render :nothing => true
            else
              render :nothing => true, :status => :internal_server_error
            end
          end
        else
          render :nothing => true, :status => :bad_request
        end
      else
        render :nothing => true, :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

  def delete
#XXX check if member somewhere!
    begin
      relation = Relation.find(params[:id])

      if relation.visible
        if RelationMember.find(:first, :joins => "INNER JOIN current_relations ON current_relations.id=current_relation_members.id", :conditions => [ "visible = 1 AND member_type='relation' and member_id=?", params[:id]])
          render :nothing => true, :status => :precondition_failed
        else
          relation.user_id = @user.id
          relation.tags = []
          relation.members = []
          relation.visible = false

          if relation.save_with_history
            render :nothing => true
          else
            render :nothing => true, :status => :internal_server_error
          end
        end
      else
        render :nothing => true, :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

  def full
    begin
      relation = Relation.find(params[:id])

      if relation.visible
        # In future, we might want to do all the data fetch in one step
        seg_ids = relation.segs + [-1]
        segments = Segment.find_by_sql "select * from current_segments where visible = 1 and id IN (#{seg_ids.join(',')})"

        node_ids = segments.collect {|segment| segment.node_a }
        node_ids += segments.collect {|segment| segment.node_b }
        node_ids += [-1]
        nodes = Node.find(node_ids, :conditions => "visible = TRUE")

        # Render
        doc = OSM::API.new.get_xml_doc
        nodes.each do |node|
          doc.root << node.to_xml_node()
        end
        segments.each do |segment|
          doc.root << segment.to_xml_node()
        end
        doc.root << relation.to_xml_node()

        render :text => doc.to_s, :content_type => "text/xml"
      else
        render :nothing => true, :status => :gone
      end
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    rescue
      render :nothing => true, :status => :internal_server_error
    end
  end

  def relations
    ids = params['relations'].split(',').collect { |w| w.to_i }

    if ids.length > 0
      doc = OSM::API.new.get_xml_doc

      Relation.find(ids).each do |relation|
        doc.root << relation.to_xml_node
      end

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :bad_request
    end
  end

  def relations_for_object(objtype)
    relationids = RelationMember.find(:all, :conditions => ['member_type=? and member_id=?', objtype, params[:id]]).collect { |ws| ws.id }.uniq

    if relationids.length > 0
      doc = OSM::API.new.get_xml_doc

      Relation.find(relationids).each do |relation|
        doc.root << relation.to_xml_node
      end

      render :text => doc.to_s, :content_type => "text/xml"
    else
      render :nothing => true, :status => :bad_request
    end
  end
end
