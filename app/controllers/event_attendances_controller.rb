class EventAttendancesController < ApplicationController
  layout "site"
  before_action :authorize_web
  before_action :set_event_attendance, :only => [:update]

  authorize_resource

  def create
    attendance = EventAttendance.new(attendance_params)
    attendance.intention = intention
    if attendance.save
      redirect_to event_path(attendance.event), :notice => t(".success")
    else
      redirect_to event_path(attendance.event), :notice => t(".failure")
    end
  end

  def update
    respond_to do |format|
      attendance = EventAttendance.find(params[:id])
      attendance.intention = intention
      if attendance.update(attendance_params)
        format.html { redirect_to @event_attendance.event, :notice => t(".success") }
      else
        format.html { render :edit }
      end
    end
  end

  private

  def intention
    # Validate the intention.
    # TODO: There must be a better way to do this.
    if params[:commit] == "Yes"
      intention = "Yes"
    elsif params[:commit] == "No"
      intention = "No"
    end
    intention
  end

  def set_event_attendance
    @event_attendance = EventAttendance.find(params[:id])
  end

  def attendance_params
    params.require(:event_attendance).permit(:event_id, :user_id)
  end
end
