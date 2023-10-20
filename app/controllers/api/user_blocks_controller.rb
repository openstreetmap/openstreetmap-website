module Api
  class UserBlocksController < ApiController
    before_action :check_api_writable, :only => :create
    before_action :authorize, :only => :create

    authorize_resource

    before_action :set_request_formats

    def show
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      @user_block = UserBlock.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      raise OSM::APINotFoundError
    end

    def create
      raise OSM::APIBadUserInput, "No user was given" unless params[:user]

      user = User.visible.find_by(:id => params[:user])
      raise OSM::APINotFoundError unless user
      raise OSM::APIBadUserInput, "No reason was given" unless params[:reason]
      raise OSM::APIBadUserInput, "No period was given" unless params[:period]

      period = Integer(params[:period], :exception => false)
      raise OSM::APIBadUserInput, "Period should be a number of hours" unless period

      max_period = UserBlock::PERIODS.max
      raise OSM::APIBadUserInput, "Period must be between 0 and #{max_period}" if period.negative? || period > max_period
      raise OSM::APIBadUserInput, "Needs_view must be true if provided" unless params[:needs_view].nil? || params[:needs_view] == "true"

      ends_at = Time.now.utc + period.hours
      needs_view = params[:needs_view] == "true"
      @user_block = UserBlock.create(
        :user => user,
        :creator => current_user,
        :reason => params[:reason],
        :ends_at => ends_at,
        :deactivates_at => (ends_at unless needs_view),
        :needs_view => needs_view
      )
      render :show
    end
  end
end
