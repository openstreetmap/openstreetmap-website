# frozen_string_literal: true

module Traces
  # Bulk change of traces that still use a legacy visibility
  class LegacyVisibilitiesController < ApplicationController
    include PaginationMethods

    layout :site_layout

    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :class => Trace

    before_action :check_database_writable, :only => :update
    before_action :offline_warning, :only => :edit
    before_action :offline_redirect, :only => :update

    def edit
      @title = t ".title"
      @params = params.permit(:visibility, :from, :to, :before, :after)

      traces = legacy_traces
      @count = traces.count
      @traces = get_page_items(traces, :includes => [:user, :tags])
    end

    def update
      visibility = params[:new_visibility]

      if Trace::VISIBILITIES.include?(visibility)
        # the traces are legacy and the new visibility is a current one, so no validation can fail
        # rubocop:disable-next Rails/SkipsModelValidations
        count = legacy_traces.update_all(:visibility => visibility)
        flash[:notice] = t ".updated", :count => count
      else
        flash[:error] = t ".invalid_visibility"
      end

      redirect_to edit_traces_legacy_visibility_path(:visibility => params[:visibility],
                                                     :from => params[:from],
                                                     :to => params[:to])
    end

    private

    ##
    # the current user's legacy traces, with the optional filters applied
    def legacy_traces
      traces = current_user.traces.visible.where(:visibility => Trace::LEGACY_VISIBILITIES)
      traces = traces.where(:visibility => params[:visibility]) if Trace::LEGACY_VISIBILITIES.include?(params[:visibility])

      from = filter_date(params[:from])
      to = filter_date(params[:to])
      traces = traces.where(:timestamp => from..) if from
      # timestamp is a datetime, so the upper bound is the start of the next day
      traces = traces.where(:timestamp => ...(to + 1)) if to

      traces
    end

    def filter_date(value)
      Date.parse(value) if value.present?
    rescue ArgumentError
      nil
    end

    def offline_warning
      flash.now[:warning] = t "traces.offline_warning.message" if Settings.status == "gpx_offline"
    end

    def offline_redirect
      render :template => "traces/offline" if Settings.status == "gpx_offline"
    end
  end
end
