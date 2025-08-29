# frozen_string_literal: true

class WaysController < ElementsController
  def show
    @type = "way"
    @feature = Way.preload(:element_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :nodes => [:element_tags, { :ways => :element_tags }]).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
