# frozen_string_literal: true

class LanguagesPanesController < ApplicationController
  before_action :authorize_web
  before_action :set_locale
  authorize_resource :class => false

  def show
    @source_page = params[:source]
    render :layout => false
  end
end
