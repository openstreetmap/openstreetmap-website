class MicrocosmMemberController < ApplicationController
  layout "site"
  before_action :authorize_web
  authorize_resource

  before_action :set_microcosm_member, :only => [:edit, :update]

  def create
    membership = MicrocosmMember.new(mm_params)
    membership.role = MicrocosmMember::Roles::MEMBER
    if membership.save!
      redirect_to microcosm_path(membership.microcosm), :notice => "Member was successfully created."
    else
      redirect_to microcosm_path(membership.microcosm), :notice => "Member was not saved."
    end
  end

  def edit; end

  def update
    respond_to do |format|
      if @microcosm_member.update(mm_params)
        format.html { redirect_to @microcosm_member.microcosm, :notice => "Microcosm Member was successfully updated." }
      else
        format.html { render :edit }
      end
    end
  end

  private

  def set_microcosm_member
    @microcosm_member = MicrocosmMember.find(params[:id])
  end

  def mm_params
    params.require(:microcosm_member).permit(:microcosm_id, :user_id, :role)
  end
end
