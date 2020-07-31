class MicrocosmMembersController < ApplicationController
  layout "site"
  before_action :authorize_web
  before_action :set_microcosm_member, :only => [:destroy, :edit, :update]
  load_and_authorize_resource

  def create
    membership = MicrocosmMember.new(create_params)
    membership.role = MicrocosmMember::Roles::MEMBER
    if membership.save
      redirect_to microcosm_path(membership.microcosm), :notice => t(".success")
    else
      redirect_to microcosm_path(membership.microcosm), :alert => t(".failure")
    end
  end

  def edit; end

  def update
    if @microcosm_member.update(update_params)
      redirect_to @microcosm_member.microcosm, :notice => t(".success")
    else
      flash[:alert] = t(".failure")
      render :edit
    end
  end

  def destroy
    # TODO: Should we remove the user from all the relevant events?
    if @microcosm_member.destroy
      redirect_to @microcosm_member.microcosm, :notice => t(".success")
    else
      flash[:alert] = t(".failure")
      render :edit
    end
  end

  private

  def set_microcosm_member
    @microcosm_member = MicrocosmMember.find(params[:id])
  end

  def create_params
    params.require(:microcosm_member).permit(:microcosm_id, :user_id, :role)
  end

  def update_params
    params.require(:microcosm_member).permit(:role)
  end
end
