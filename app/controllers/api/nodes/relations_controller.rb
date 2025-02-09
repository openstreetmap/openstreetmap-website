module Api
  module Nodes
    class RelationsController < ApiController
      authorize_resource

      before_action :set_request_formats

      def index
        @relations = Relation
                     .visible
                     .where(:id => RelationMember.where(
                       :member_type => "Node",
                       :member_id => params[:node_id]
                     ).select(:relation_id))

        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      end
    end
  end
end
