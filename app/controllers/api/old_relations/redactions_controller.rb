# frozen_string_literal: true

module Api
  module OldRelations
    class RedactionsController < OldElements::RedactionsController
      private

      def lookup_old_element
        @old_element = OldRelation.find(params.expect(:relation_id, :version))
      end
    end
  end
end
