# frozen_string_literal: true

class SharePanesController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  authorize_resource :class => false

  def show
    @downloadable_layers = MapLayers.full_definitions("config/layers.yml")
                                    .select { |layer| layer["canDownloadImage"] }
    render :layout => false
  end
end
