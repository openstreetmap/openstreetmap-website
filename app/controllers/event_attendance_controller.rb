class EventAttendanceController < ApplicationController
  layout "site"
  before_action :authorize_web

  authorize_resource

  def create
    attendance = EventAttendance.new(attendance_params)
    # Validate the intention.
    if params[:commit] == "Yes"
      intention = "Yes"
    elsif params[:commit] == "No"
      intention = "No"
    end
    attendance.intention = intention
    if attendance.save!
      redirect_to event_path(attendance.event), notice: 'Attendance was successfully saved.'
    end
  end

  private

  def attendance_params
    params.require(:event_attendance).permit(:event_id, :user_id)
  end

end
