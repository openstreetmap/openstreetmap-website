module Api
  module Relations
    class RelationsController < ApiController
      authorize_resource

      before_action :set_request_formats

      def index
        @relations = Relation
                     .visible
                     .where(:id => RelationMember.where(
                       :member_type => "Relation",
                       :member_id => params[:relation_id]
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
