# frozen_string_literal: true

class OldRelationsController < OldElementsController
  def index
    @type = "relation"
    @current_feature = @feature = Relation.preload(:element_tags).find(params[:id])
    @old_features, @newer_features_version, @older_features_version = get_page_items(
      OldRelation.where(:relation_id => params[:id]),
      :cursor_column => :version,
      :includes => [:old_tags, { :changeset => [:changeset_tags, :user], :old_members => :member }]
    )
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end

  def show
    @type = "relation"
    @current_feature = Relation.find(params[:id])
    @feature = OldRelation.preload(:old_tags, :changeset => [:changeset_tags, :user]).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
