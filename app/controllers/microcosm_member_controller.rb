class MicrocosmMemberController < ApplicationController
  layout "site"
  authorize_resource

  def create
    membership = MicrocosmMember.new(mm_params)
    membership.role = MicrocosmMember::Roles::MEMBER
    if membership.save!
      redirect_to microcosm_path(membership.microcosm), notice: 'Member was successfully created.'
    end
  end

  private

  def mm_params
    params.require(:microcosm_member).permit(:microcosm_id, :user_id)
  end
end
