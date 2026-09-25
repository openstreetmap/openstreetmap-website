# frozen_string_literal: true

module Api
  module OldNodes
    class RedactionsController < OldElements::RedactionsController
      private

      def lookup_old_element
        @old_element = OldNode.find(params.expect(:node_id, :version))
      end
    end
  end
end
