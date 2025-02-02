module Api
  module Relations
    class RelationsController < ApiController
      authorize_resource

      before_action :set_request_formats

      def index
        relation_ids = RelationMember.where(:member_type => "Relation", :member_id => params[:relation_id]).collect(&:relation_id).uniq

        @relations = []

        Relation.find(relation_ids).each do |relation|
          @relations << relation if relation.visible
        end

        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      end
    end
  end
end
