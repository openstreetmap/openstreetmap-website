class EventAttendancesController < ApplicationController
  layout "site"
  before_action :authorize_web
  before_action :set_event_attendance, :only => [:update]

  load_and_authorize_resource

  def create
    attendance = EventAttendance.new(event_attendance_params)
    attendance.intention = valid_intention
    if attendance.save
      redirect_to event_path(attendance.event), :notice => t(".success")
    else
      flash[:alert] = t(".failure")
      render event_path(attendance.event)
    end
  end

  def update
    attendance = EventAttendance.find(params[:id])
    attendance.intention = valid_intention
    if attendance.update(event_attendance_params)
      redirect_to @event_attendance.event, :notice => t(".success")
    else
      flash[:alert] = t(".failure")
      render :edit
    end
  end

  private

  def valid_intention
    # We have this because some forms have 2 submit buttons, one for Yes and one for No.
    # if params.has_key[:commit] && !params.has_key[:intention]
    #   params[:intention] = params[:intention]
    # end
    # Validate the intention.
    intention = params[:event_attendance][:intention]
    unless EventAttendance::Intentions::ALL_INTENTIONS.include?(intention)
      flash[:error] = t("event_attendances.filter.not_an_intention", :intention => intention)
      redirect_to event_path(@event_attendance.event)
    end
    intention
  end

  def set_event_attendance
    @event_attendance = EventAttendance.find(params[:id])
  end

  def event_attendance_params
    params.require(:event_attendance).permit(:event_id, :user_id)
  end
end
