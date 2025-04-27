# frozen_string_literal: true

module Api
  module Changesets
    class ClosesController < ApiController
      before_action :check_api_writable
      before_action :authorize

      authorize_resource :class => Changeset

      before_action :require_public_data

      # Helper methods for checking consistency
      include ConsistencyValidations

      ##
      # marks a changeset as closed. this may be called multiple times
      # on the same changeset, so is idempotent.
      def update
        changeset = Changeset.find(params[:changeset_id])
        check_changeset_consistency(changeset, current_user)

        # to close the changeset, we'll just set its closed_at time to
        # now. this might not be enough if there are concurrency issues,
        # but we'll have to wait and see.
        changeset.set_closed_time_now

        changeset.save!
        head :ok
      end
    end
  end
end
