class EventsController < ApplicationController
  layout "site"
  before_action :authorize_web
  before_action :set_event, :only => [:edit, :show]

  authorize_resource

  # GET /events
  # GET /events.json
  def index
    @events = Event.all
  end

  # GET /events/new
  def new
    @event = Event.new
    @event.microcosm_id = params[:microcosm_id]
  end

  # POST /events
  # POST /events.json
  def create
    # TODO: Do we need a transaction here?
    @event = Event.new(event_params)
    @event_organizer = EventOrganizer.new(:event => @event, :user => current_user)

    respond_to do |format|
      if @event.save && @event_organizer.save
        format.html { redirect_to @event, :notice => t(".success") }
        format.json { render :show, :status => :created, :location => @event }
      else
        format.html { render :new }
        format.json { render :json => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /events/1/edit
  def edit; end

  # GET /events/1
  # GET /events/1.json
  def show
    @my_attendance = EventAttendance.find_or_initialize_by(:event_id => @event.id, :user_id => current_user&.id)
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :moment, :location, :description, :microcosm_id)
  end
end
