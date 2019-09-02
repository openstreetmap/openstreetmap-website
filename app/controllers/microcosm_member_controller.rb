class MicrocosmMemberController < ApplicationController
  layout "site"
  authorize_resource

  def create
#   logger.error(mm_params.inspect)
#   non_mm_params = mm_params.extract!(:mm_params)
#   # TODO: mm_params at this piont still has :non_mm_params.  Bug?  Perhaps due to permitted: true

#   mm2 = mm_params.slice(:microcosm_id, :user_id)
    membership = MicrocosmMember.new(mm_params)
    if membership.save!
      redirect_to microcosm_path(membership.microcosm), notice: 'Member was successfully created.'
    end
  end

  private

  def mm_params
    params.require(:microcosm_member).permit(:microcosm_id, :user_id)
  end
end
