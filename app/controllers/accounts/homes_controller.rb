module Accounts
  class HomesController < ApplicationController
    layout :map_layout

    before_action :authorize_web
    before_action :set_locale
    before_action :require_oauth

    authorize_resource :class => :account_home

    def show; end
  end
end
