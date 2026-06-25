# frozen_string_literal: true

module Traces
  class FeedsController < ApplicationController
    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :class => Trace

    def show
      @traces = Trace.visible_to_all.visible

      if params[:display_name]
        target_user = User.active.find_by(:display_name => params[:display_name])
        @traces = target_user ? target_user.traces.visible_to_all.visible : Trace.none
      end

      @traces = @traces.tagged(params[:tag]) if params[:tag]
      @traces = @traces.order(:timestamp => :desc)
      @traces = @traces.limit(20)
      @traces = @traces.includes(:user)
    end
  end
end
