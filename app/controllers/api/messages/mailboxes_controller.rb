module Api
  module Messages
    class MailboxesController < ApiController
      before_action :authorize

      authorize_resource :message

      before_action :set_request_formats

      private

      def show_messages
        @messages = @messages.where(:muted => false)
        if params[:order].nil? || params[:order] == "newest"
          @messages = @messages.where(:id => ..params[:from_id]) unless params[:from_id].nil?
          @messages = @messages.order(:id => :desc)
        elsif params[:order] == "oldest"
          @messages = @messages.where(:id => params[:from_id]..) unless params[:from_id].nil?
          @messages = @messages.order(:id => :asc)
        else
          raise OSM::APIBadUserInput, "Invalid order specified"
        end

        limit = params[:limit]
        if !limit
          limit = Settings.default_message_query_limit
        elsif !limit.to_i.positive? || limit.to_i > Settings.max_message_query_limit
          raise OSM::APIBadUserInput, "Messages limit must be between 1 and #{Settings.max_message_query_limit}"
        else
          limit = limit.to_i
        end

        @messages = @messages.limit(limit)

        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      end
    end
  end
end
