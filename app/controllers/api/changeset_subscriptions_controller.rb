module Api
  class ChangesetSubscriptionsController < ApiController
    before_action :check_api_writable
    before_action :authorize

    authorize_resource

    before_action :require_public_data
    before_action :set_request_formats

    ##
    # Adds a subscriber to the changeset
    def create
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:changeset_id]

      # Extract the arguments
      changeset_id = params[:changeset_id].to_i

      # Find the changeset and check it is valid
      @changeset = Changeset.find(changeset_id)
      raise OSM::APIChangesetAlreadySubscribedError, @changeset if @changeset.subscribers.include?(current_user)

      # Add the subscriber
      @changeset.subscribers << current_user

      respond_to do |format|
        format.xml
        format.json
      end
    end

    ##
    # Removes a subscriber from the changeset
    def destroy
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:changeset_id]

      # Extract the arguments
      changeset_id = params[:changeset_id].to_i

      # Find the changeset and check it is valid
      @changeset = Changeset.find(changeset_id)
      raise OSM::APIChangesetNotSubscribedError, @changeset unless @changeset.subscribers.include?(current_user)

      # Remove the subscriber
      @changeset.subscribers.delete(current_user)

      respond_to do |format|
        format.xml
        format.json
      end
    end
  end
end
