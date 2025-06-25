module Users
  class ListsController < ApplicationController
    include PaginationMethods

    layout "site"

    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :class => :users_list

    ##
    # display a list of users matching specified criteria
    def show
      @params = params.permit(:status, :username, :ip, :edits, :before, :after)

      users = User.all
      users = users.where(:status => @params[:status]) if @params[:status].present?
      users = users.where("LOWER(email) = LOWER(?) OR LOWER(NORMALIZE(display_name, NFKC)) = LOWER(NORMALIZE(?, NFKC))", @params[:username], @params[:username]) if @params[:username].present?
      users = users.where("creation_address <<= ?", @params[:ip]) if @params[:ip].present?
      users = users.where(:changesets_count => 0) if @params[:edits] == "no"
      users = users.where.not(:changesets_count => 0) if @params[:edits] == "yes"

      @users_count = users.limit(501).count
      @users_count = I18n.t("count.at_least_pattern", :count => 500) if @users_count > 500

      @users, @newer_users_id, @older_users_id = get_page_items(users, :limit => 50)

      render :partial => "page" if turbo_frame_request_id == "pagination"
    end

    ##
    # update status of selected users
    def update
      ids = params.fetch(:user, {}).keys.collect(&:to_i)

      User.where(:id => ids).update_all(:status => "confirmed") if params[:confirm]
      User.where(:id => ids).update_all(:status => "deleted") if params[:hide]

      redirect_to url_for(params.permit(:status, :username, :ip, :edits, :before, :after))
    end
  end
end
