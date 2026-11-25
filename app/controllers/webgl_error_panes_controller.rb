# frozen_string_literal: true

class WebglErrorPanesController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  authorize_resource :class => false

  def show
    respond_to do |format|
      format.html { render :layout => false }
    end
  end
end
