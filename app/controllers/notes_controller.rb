class NotesController < ApplicationController
  layout "site", :only => [:mine]

  before_action :check_api_readable
  before_action :authorize_web

  authorize_resource

  before_action :set_locale
  around_action :api_call_handle_error, :api_call_timeout

  ##
  # Display a list of notes by a specified user
  def mine
    if params[:display_name]
      if @user = User.active.find_by(:display_name => params[:display_name])
        @params = params.permit(:display_name)
        @title = t "notes.mine.title", :user => @user.display_name
        @heading = t "notes.mine.heading", :user => @user.display_name
        @description = t "notes.mine.subheading", :user => render_to_string(:partial => "user", :object => @user)
        @page = (params[:page] || 1).to_i
        @page_size = 10
        @notes = @user.notes
        @notes = @notes.visible unless current_user&.moderator?
        @notes = @notes.order("updated_at DESC, id").distinct.offset((@page - 1) * @page_size).limit(@page_size).preload(:comments => :author).to_a
      else
        @title = t "users.no_such_user.title"
        @not_found_user = params[:display_name]

        render :template => "users/no_such_user", :status => :not_found
      end
    end
  end
end
