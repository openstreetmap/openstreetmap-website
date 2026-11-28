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
    respond_to do |format|
      format.html do
        @current_feature = Way.find(params.expect(:id))
        @feature = OldWay.preload(:old_tags, :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:element_tags, :ways] }).find(params.expect(:id, :version))
      end
      format.json do
        way = OldWay.find(params.expect(:id, :version))
        render :json => { :elements => way.map_elements }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { render "browse/not_found", :status => :not_found }
      format.json { head :not_found }
    end
  end
end
