class EventAttendancesController < ApplicationController
  layout "site"
  before_action :authorize_web
  before_action :set_event_attendance, :only => [:update]

  authorize_resource

  def create
    attendance = EventAttendance.new(event_attendance_params)
    if attendance.save
      redirect_to event_path(attendance.event), :notice => t(".success")
    else
      redirect_to event_path(attendance.event), :alert => t(".failure")
    end
  end

  def update
    respond_to do |format|
      if @event_attendance.update(update_params)
        format.html { redirect_to @event_attendance.event, :notice => t(".success") }
      else
        format.html { redirect_to :edit, :alert => t(".failure") }
      end
    end
  end

  private

  def set_event_attendance
    @event_attendance = EventAttendance.find(params[:id])
  end

  def event_attendance_params
    params.require(:event_attendance).permit(:event_id, :user_id, :intention)
  end

  def update_params
    params.require(:event_attendance).permit(:intention)
  end
end
