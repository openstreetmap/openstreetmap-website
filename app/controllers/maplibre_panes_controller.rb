# frozen_string_literal: true

class MaplibrePanesController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  authorize_resource :class => false

  def show
    render :layout => false
  end
end
