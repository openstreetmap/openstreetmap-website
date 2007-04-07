class SiteController < ApplicationController
  before_filter :authorize_web
  before_filter :require_user, :only => [:edit]
  def index

  end
end
