module Api
  module OldRelations
    class RedactionsController < OldElements::RedactionsController
      private

      def lookup_old_element
        @old_element = OldRelation.find([params[:relation_id], params[:version]])
      end
    end
  end
end
