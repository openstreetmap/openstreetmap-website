class SiteController < ApplicationController
  before_filter :authorize_web
  before_filter :require_user, :only => [:edit]

  def goto_way
    way = Way.find(params[:id])

    begin
      node = way.way_segments.first.segment.from_node
      redirect_to :controller => 'site', :action => 'index', :lat => node.latitude, :lon => node.longitude, :zoom => 6
    rescue
      redirect_to :back
    end
  end

end
