module Api
  module Ways
    class RelationsController < ApiController
      authorize_resource

      before_action :set_request_formats

      def index
        @relations = Relation
                     .visible
                     .where(:id => RelationMember.where(
                       :member_type => "Way",
                       :member_id => params[:way_id]
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
