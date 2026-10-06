# frozen_string_literal: true

module Api
  class GpxEventsController < ApiController
    include QueryMethods

    authorize_resource

    before_action :set_request_formats

    ##
    # list the traces that were added or removed, oldest event first
    #
    # A client keeps the id of the last event it has read and sends it as
    # "since" to get the events after it. A client that doesn't have an id
    # can use "from" to start at the first event created at or after a time.
    def index
      @events = GpxEvent.order(:id)
      @events = @events.where(:id => (since_id + 1)..) if params[:since]
      @events = @events.where(:id => from_id..) if params[:from]
      @events = query_limit(@events)

      @last_id = GpxEvent.maximum(:id) || 0
    end

    private

    def since_id
      raise OSM::APIBadUserInput, "Event id #{params[:since]} is in a wrong format" unless /\A\d+\z/.match?(params[:since])

      params[:since].to_i
    end

    ##
    # the id of the first event created at or after the "from" time, or an
    # id after the last event when there isn't one
    def from_id
      from = Time.parse(params[:from]).utc

      GpxEvent.where(:created_at => from..).order(:created_at, :id).pick(:id) || (GpxEvent.maximum(:id).to_i + 1)
    rescue ArgumentError
      raise OSM::APIBadUserInput, "Date #{params[:from]} is in a wrong format"
    end
  end
end
