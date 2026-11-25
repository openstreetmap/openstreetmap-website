# frozen_string_literal: true

class RelationMembersController < ElementsController
  def show
    @type = "relation"
    @feature = Relation.preload(:relation_members => { :member => :element_tags }).find(params.expect(:id))
    @frame_id = "member_relation_#{@feature.id}"

    respond_to do |format|
      format.html { render :partial => "browse/relation_member_frame", :locals => { :relation => @feature, :frame_id => @frame_id } }
    end
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
