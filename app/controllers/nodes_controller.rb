# frozen_string_literal: true

class NodesController < ElementsController
  def show
    @type = "node"
    @feature = Node.preload(:element_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :ways => :element_tags).find(params.expect(:id))
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
