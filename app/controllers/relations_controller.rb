class RelationsController < ElementsController
  def show
    @type = "relation"
    @feature = Relation.preload(:relation_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :relation_members => :member).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
