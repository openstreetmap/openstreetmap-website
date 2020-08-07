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
    issues = @microcosm_member.can_be_deleted
    if issues.empty? && @microcosm_member.destroy
      redirect_to @microcosm_member.microcosm, :notice => t(".success")
    else
      issues = issues.map { |i| t("activerecord.errors.models.microcosm_member." + i.to_s) }
      issues = issues.to_sentence.capitalize
      redirect_to @microcosm_member.microcosm, :error => "#{t('.failure')} #{issues}."
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
