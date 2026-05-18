# frozen_string_literal: true

class OldWaysController < OldElementsController
  def index
    @type = "way"
    @current_feature = @feature = Way.preload(:element_tags).find(params.expect(:id))
    @old_features = get_page_items(
      OldWay.where(:way_id => params[:id]),
      :cursor_column => :version,
      :includes => [:old_tags, { :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:element_tags, :ways] } }]
    )
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end

  def show
    @type = "way"
    @current_feature = Way.find(params.expect(:id))
    @feature = OldWay.preload(:old_tags, :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:element_tags, :ways] }).find(params.expect(:id, :version))
  rescue ActiveRecord::RecordNotFound
    render "browse/not_found", :status => :not_found
  end
end
