class SiteController < ApplicationController
  layout 'site',:except => [:key]

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:edit]

  def export
    render :action => 'index'
  end

  def key
    expires_in 7.days, :public => true
  end
end
