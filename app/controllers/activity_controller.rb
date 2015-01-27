# Handles activity views

class ActivityController < ApplicationController

  def display
    render :action => :display, :layout => map_layout
  end
end