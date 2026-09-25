# frozen_string_literal: true

module Api
  module OldWays
    class RedactionsController < OldElements::RedactionsController
      private

      def lookup_old_element
        @old_element = OldWay.find(params.expect(:way_id, :version))
      end
    end
  end
end
