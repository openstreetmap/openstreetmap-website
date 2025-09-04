# frozen_string_literal: true

class DirectionsController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action :require_oauth
  authorize_resource :class => :directions

  def show; end
end
