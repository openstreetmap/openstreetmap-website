class EventAttendancesController < ApplicationController
  layout "site"
  before_action :authorize_web
  before_action :set_event_attendance, :only => [:update]

  load_and_authorize_resource

  def create
    attendance = EventAttendance.new(create_params)
    if attendance.save
      redirect_to event_path(attendance.event), :notice => t(".success")
    else
      # flash[:alert] = t(".failure")
      # # render event_path(attendance.event)
      # @event = attendance.event
      # render "events/show"
      redirect_to event_path(attendance.event), :alert => t(".failure")
    end
  end

  def update
    if @event_attendance.update(update_params)
      redirect_to @event_attendance.event, :notice => t(".success")
    else
      flash[:alert] = t(".failure")
      render event_path(@event_attendance.event)
    end
  end

  private

  def set_event_attendance
    @event_attendance = EventAttendance.find(params[:id])
  end

  def create_params
    params.require(:event_attendance).permit(:event_id, :user_id, :intention)
  end

  # Only update is permitted to be updated.
  def update_params
    params.require(:event_attendance).permit(:intention)
  end
end
