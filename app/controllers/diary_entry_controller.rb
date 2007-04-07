class DiaryEntryController < ApplicationController
  layout 'site'
  
  before_filter :authorize_web
  before_filter :require_user

  def new
    if params[:diary_entry]     
      @entry = DiaryEntry.new(@params[:diary_entry])
      @entry.user = @user
      if @entry.save 
        redirect_to :controller => 'user', :action => 'diary', :display_name => @user.display_name 
      end
    end
  end
end
