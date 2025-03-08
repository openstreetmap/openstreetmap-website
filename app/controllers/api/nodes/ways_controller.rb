module Api
  module Nodes
    class WaysController < ApiController
      authorize_resource

      before_action :set_request_formats

      ##
      # returns all the ways which are currently using the node given in the
      # :node_id parameter. note that this used to return deleted ways as well, but
      # this seemed not to be the expected behaviour, so it was removed.
      def index
        @ways = Way
                .visible
                .where(:id => WayNode.where(
                  :node_id => params[:node_id]
                ).select(:way_id))

        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      end
    end
  end
end
