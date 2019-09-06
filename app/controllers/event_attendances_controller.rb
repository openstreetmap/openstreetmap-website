class EventAttendancesController < ApplicationController
  layout "site"
  before_action :authorize_web
  before_action :set_event_attendance, :only => [:edit, :show, :update]

  authorize_resource

  def create
    attendance = EventAttendance.new(attendance_params)
    attendance.intention = get_intention
    if attendance.save!
      redirect_to event_path(attendance.event), notice: 'Attendance was successfully saved.'
    end
  end

  def update
    respond_to do |format|
      attendance = EventAttendance.find(params[:id])
      attendance.intention = get_intention
      if attendance.update(attendance_params)
        format.html { redirect_to @event_attendance.event, notice: 'Attendance was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  private

  def get_intention
    # Validate the intention.
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
