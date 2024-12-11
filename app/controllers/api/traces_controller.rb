module Api
  class TracesController < ApiController
    before_action :check_api_writable, :only => [:create, :update, :destroy]
    before_action :set_locale
    before_action :authorize

    authorize_resource

    before_action :offline_error, :only => [:create, :destroy]
    skip_around_action :api_call_timeout, :only => :create

    def show
      @trace = Trace.visible.find(params[:id])

      head :forbidden unless @trace.public? || @trace.user == current_user
    end

    def create
      tags = params[:tags] || ""
      description = params[:description] || ""
      visibility = params[:visibility]

      if visibility.nil?
        visibility = if params[:public]&.to_i&.nonzero?
                       "public"
                     else
                       "private"
                     end
      end

      if params[:file].respond_to?(:read)
        trace = do_create(params[:file], tags, description, visibility)

        if trace.id
          trace.schedule_import
          render :plain => trace.id.to_s
        elsif trace.valid?
          head :internal_server_error
        else
          head :bad_request
        end
      else
        head :bad_request
      end
    end

    def update
      trace = Trace.visible.find(params[:id])

      if trace.user == current_user
        trace.update_from_xml(request.raw_post)
        trace.save!

        head :ok
      else
        head :forbidden
      end
    end

    def destroy
      trace = Trace.visible.find(params[:id])

      if trace.user == current_user
        trace.visible = false
        trace.save!
        trace.schedule_destruction

        head :ok
      else
        head :forbidden
      end
    end

    private

    def do_create(file, tags, description, visibility)
      # Sanitise the user's filename
      name = file.original_filename.gsub(/[^a-zA-Z0-9.]/, "_")

      # Create the trace object, falsely marked as already
      # inserted to stop the import daemon trying to load it
      trace = Trace.new(
        :name => name,
        :tagstring => tags,
        :description => description,
        :visibility => visibility,
        :inserted => false,
        :user => current_user,
        :timestamp => Time.now.utc,
        :file => file
      )

      # Save the trace object
      trace.save!

      # Finally save the user's preferred privacy level
      if pref = current_user.preferences.find_by(:k => "gps.trace.visibility")
        pref.v = visibility
        pref.save
      else
        current_user.preferences.create(:k => "gps.trace.visibility", :v => visibility)
      end

      trace
    end

    def offline_error
      report_error "GPX files offline for maintenance", :service_unavailable if Settings.status == "gpx_offline"
    end
  end
end
