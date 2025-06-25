module Traces
  class DataController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :class => Trace

    before_action :offline_redirect

    def show
      trace = Trace.visible.find(params[:trace_id])

      if trace.public? || (current_user && current_user == trace.user)
        if Acl.no_trace_download(request.remote_ip)
          head :forbidden
        elsif request.format == Mime[:xml]
          send_data(trace.xml_file.read, :filename => "#{trace.id}.xml", :type => request.format.to_s, :disposition => "attachment")
        elsif request.format == Mime[:gpx]
          send_data(trace.xml_file.read, :filename => "#{trace.id}.gpx", :type => request.format.to_s, :disposition => "attachment")
        elsif trace.file.attached?
          redirect_to rails_blob_path(trace.file, :disposition => "attachment")
        else
          send_file(trace.trace_name, :filename => "#{trace.id}#{trace.extension_name}", :type => trace.mime_type, :disposition => "attachment")
        end
      else
        head :not_found
      end
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def offline_redirect
      render :template => "traces/offline" if Settings.status == "gpx_offline"
    end
  end
end
