module Api
  module Traces
    class DataController < ApiController
      before_action :set_locale
      before_action :authorize

      authorize_resource :trace

      before_action :offline_error

      def show
        trace = Trace.visible.find(params[:trace_id])

        if trace.public? || trace.user == current_user
          if request.format == Mime[:xml]
            send_data(trace.xml_file.read, :filename => "#{trace.id}.xml", :type => request.format.to_s, :disposition => "attachment")
          elsif request.format == Mime[:gpx]
            send_data(trace.xml_file.read, :filename => "#{trace.id}.gpx", :type => request.format.to_s, :disposition => "attachment")
          elsif trace.file.attached?
            redirect_to rails_blob_path(trace.file, :disposition => "attachment")
          else
            send_file(trace.trace_name, :filename => "#{trace.id}#{trace.extension_name}", :type => trace.mime_type, :disposition => "attachment")
          end
        else
          head :forbidden
        end
      end

      private

      def offline_error
        report_error "GPX files offline for maintenance", :service_unavailable if Settings.status == "gpx_offline"
      end
    end
  end
end
