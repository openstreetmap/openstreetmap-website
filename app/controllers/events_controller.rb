class EventsController < ApplicationController
  layout "site"
  before_action :authorize_web
  before_action :set_event, :only => [:edit, :show, :update]
  # This needs to be one before load_and_authorize_resource, so cancancan will be handed
  # an event that contains a community, based on the input parameter community_id.
  before_action :set_params_for_new, :only => [:new]

  load_and_authorize_resource

  # GET /events
  # GET /events.json
  def index
    if params[:community_id]
      @community = Community.friendly.find(params[:community_id])
      @events = @community.events
    else
      @community = nil
      @events = Event.all
    end
  rescue ActiveRecord::RecordNotFound
    @not_found_community = params[:community_id]
    render :template => "communities/no_such_community", :status => :not_found
  end

  # GET /events/1
  # GET /events/1.json
  def show
    @community = Community.friendly.find(params[:community_id]) if params[:community_id]
    @my_attendance = EventAttendance.find_or_initialize_by(:event_id => @event.id, :user_id => current_user&.id)
    @yes_check = @my_attendance.intention == EventAttendance::Intentions::YES ? "✓" : ""
    @no_check = @my_attendance.intention == EventAttendance::Intentions::NO ? "✓" : ""
    @maybe_check = @my_attendance.intention == EventAttendance::Intentions::MAYBE ? "✓" : ""
    @yes_disabled = @my_attendance.intention == EventAttendance::Intentions::YES
    @no_disabled = @my_attendance.intention == EventAttendance::Intentions::NO
    @maybe_disabled = @my_attendance.intention == EventAttendance::Intentions::MAYBE
  rescue ActiveRecord::RecordNotFound
    @not_found_community = params[:community_id]
    render :template => "communities/no_such_community", :status => :not_found
  end

  # GET /events/new
  def new
    @title = t ".new"
    @event = Event.new(event_params_new)
  end

  # GET /events/1/edit
  def edit; end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)
    @event_organizer = EventOrganizer.new(:event => @event, :user => current_user)

    if @event.save && @event_organizer.save
      warn_if_event_in_past
      redirect_to @event, :notice => t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :new
    end
  end

  def update
    if @event.update(event_params)
      redirect_to @event, :notice => t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  private

  def warn_if_event_in_past
    flash[:warning] = t "events.show.past" if @event.past?
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def set_params_for_new
    @params = event_params_new
  end

  def event_params
    params.require(:event).permit(
      :title, :moment, :location, :location_url,
      :latitude, :longitude, :description, :community_id
    )
  end

  def event_params_new
    params.require(:event).permit(:community_id)
  end
end
