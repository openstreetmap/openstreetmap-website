# frozen_string_literal: true

class RelationsController < ElementsController
  def show
    @type = "relation"
    @feature = Relation.preload(:element_tags, :containing_relation_members, :changeset => [:changeset_tags, :user]).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
