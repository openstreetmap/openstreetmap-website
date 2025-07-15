module Api
  module OldWays
    class RedactionsController < OldElements::RedactionsController
      private

      def lookup_old_element
        @old_element = OldWay.find([params[:way_id], params[:version]])
      end
    end
  end
end
