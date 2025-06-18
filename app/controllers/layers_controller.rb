class LayersController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  authorize_resource :class => false

  def show
    expires_in 7.days, :public => true
    render :layout => false
  end
end
