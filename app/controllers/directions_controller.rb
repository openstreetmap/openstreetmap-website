class DirectionsController < ApplicationController
  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_oauth, :only => [:search]

  def search
    render :layout => map_layout
  end
end
