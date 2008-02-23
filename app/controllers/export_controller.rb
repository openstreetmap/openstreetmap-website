class ExportController < ApplicationController
  def start
    render :update do |page|
      page.replace_html :sidebar_content, :partial => 'start'
      page.call "openSidebar"
    end
  end
end
