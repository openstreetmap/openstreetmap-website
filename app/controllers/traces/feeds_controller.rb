module Traces
  class FeedsController < ApplicationController
    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :class => Trace

    def show
      @traces = Trace.visible_to_all.visible

      @traces = @traces.joins(:user).where(:users => { :display_name => params[:display_name] }) if params[:display_name]

      @traces = @traces.tagged(params[:tag]) if params[:tag]
      @traces = @traces.order("timestamp DESC")
      @traces = @traces.limit(20)
      @traces = @traces.includes(:user)
    end
  end
end
