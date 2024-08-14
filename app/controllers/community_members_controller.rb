class CommunityMembersController < ApplicationController
  layout "site"
  before_action :authorize_web
  before_action :set_community_member, :only => [:destroy, :edit, :update]
  load_and_authorize_resource :except => [:create]
  authorize_resource

  def index
    @community = Community.friendly.find(params[:community_id])
    @roles = CommunityMember::Roles::ALL_ROLES.map(&:pluralize)
  rescue ActiveRecord::RecordNotFound
    @not_found_community = params[:community_id]
    render :template => "communities/no_such_community", :status => :not_found
  end

  def edit; end

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

  def update
    if @community_member.update(update_params)
      redirect_to @community_member.community, :notice => t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  def destroy
    issues = @community_member.can_be_deleted
    if issues.empty? && @community_member.destroy
      redirect_to @community_member.community, :notice => t(".success")
    else
      issues = issues.map { |i| t("activerecord.errors.models.community_member.#{i}") }
      issues = issues.to_sentence.capitalize
      flash[:error] = "#{t('.failure')} #{issues}."
      redirect_to community_community_members_path(@community_member.community)
    end
  end

  private

  def set_community_member
    @community_member = CommunityMember.find(params[:id])
  end

  def create_params
    params.require(:community_member).permit(:community_id, :user_id)
  end

  def update_params
    params.require(:community_member).permit(:role)
  end
end
