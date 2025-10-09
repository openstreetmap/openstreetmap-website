# frozen_string_literal: true

module Api
  module Changesets
    class UploadsController < ApiController
      before_action :check_api_writable
      before_action :authorize

      authorize_resource :class => Changeset

      before_action :require_public_data

      skip_around_action :api_call_timeout

      # Helper methods for checking consistency
      include ConsistencyValidations

      ##
      # Upload a diff in a single transaction.
      #
      # This means that each change within the diff must succeed, i.e: that
      # each version number mentioned is still current. Otherwise the entire
      # transaction *must* be rolled back.
      #
      # Furthermore, each element in the diff can only reference the current
      # changeset.
      #
      # Returns: a diffResult document, as described in
      # http://wiki.openstreetmap.org/wiki/OSM_Protocol_Version_0.6
      def create
        Changeset.transaction do
          changeset = Changeset.lock.find(params[:changeset_id])
          check_changeset_consistency(changeset, current_user)

          diff_reader = DiffReader.new(request.raw_post, changeset)
          result = diff_reader.commit
          # the number of changes in this changeset has already been
          # updated and is visible in this transaction so we don't need
          # to allow for any more when checking the limit
          check_rate_limit(0)
          render :xml => result.to_s
        end
      end
    end
  end
end
