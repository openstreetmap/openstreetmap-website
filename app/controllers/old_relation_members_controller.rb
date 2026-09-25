# frozen_string_literal: true

class OldRelationMembersController < OldElementsController
  def show
    @type = "relation"
    @current_feature = Relation.find(params.expect(:id))
    @feature = OldRelation.preload(:old_members => { :member => :element_tags }).find(params.expect(:id, :version))
    @frame_id = "member_relation_#{@feature.id}"

    return deny_access(nil) if @feature.redacted? && params[:show_redactions].blank?

    render :partial => "browse/relation_member_frame", :locals => { :relation => @feature, :frame_id => @frame_id }
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
