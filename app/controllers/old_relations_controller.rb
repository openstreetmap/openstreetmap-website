class OldRelationsController < OldElementsController
  def index
    @type = "relation"
    @feature = Relation.preload(:relation_tags, :old_relations => [:old_tags, { :changeset => [:changeset_tags, :user], :old_members => :member }]).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end

  def show
    @type = "relation"
    @feature = OldRelation.preload(:old_tags, :changeset => [:changeset_tags, :user], :old_members => :member).find([params[:id], params[:version]])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
