class CommunityMembersController < ApplicationController
  layout "site"
  before_action :authorize_web

  load_and_authorize_resource :except => [:create, :new]
  authorize_resource

  def index
    @community = Community.friendly.find(params[:community_id])
    @memberships = @community.community_members
  rescue ActiveRecord::RecordNotFound
    @not_found_community = params[:community_id]
    render :template => "communities/no_such_community", :status => :not_found
  end

  def create
    # membership = CommunityMember.new(create_params)
    # If there's no given user, default to the current_user.
    membership = CommunityMember.new(create_params.reverse_merge!(:user_id => current_user.id))
    membership.role = CommunityMember::Roles::MEMBER
    if membership.save
      redirect_to community_path(membership.community), :notice => t(".success")
    else
      # There are 2 reasons we may get here.
      # 1. database failure / disk full
      # 2. the community does not exist
      # Either way, sending the user to the communities list page is ok.
      redirect_to communities_path, :alert => t(".failure")
    end
  end

  private

  def create_params
    params.require(:community_member).permit(:community_id, :user_id)
  end
end
