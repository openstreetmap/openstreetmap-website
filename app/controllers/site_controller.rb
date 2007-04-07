class SiteController < ApplicationController
  before_filter :authorize_web
  before_filter :require_user, :only => [:edit]


  def search
    @tags = WayTag.find(:all, :conditions => ["match(v) against (?)", params[:query][:query].to_s] )
  end

end
