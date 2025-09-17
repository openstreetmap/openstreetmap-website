# frozen_string_literal: true

class LayersPanesController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  authorize_resource :class => false

  def show
    @base_layers = MapLayers.full_definitions("config/layers.yml")
    @overlay_layers = [{ :layer_id => "noteLayer", :name => "notes", :max_area => Settings.max_note_request_area },
                       { :layer_id => "dataLayer", :name => "data", :max_area => Settings.max_request_area },
                       { :layer_id => "gpsLayer", :name => "gps" }]
    render :layout => false
  end
end
