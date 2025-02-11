module Api
  module OldNodes
    class RedactionsController < OldElements::RedactionsController
      private

      def lookup_old_element
        @old_element = OldNode.find([params[:node_id], params[:version]])
      end
    end
  end
end
