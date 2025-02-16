module Accounts
  class PdDeclarationsController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => :account_pd_declaration

    def show; end

    def create
      if current_user.consider_pd
        flash[:warning] = t(".already_declared")
      else
        current_user.consider_pd = params[:consider_pd]

        if current_user.consider_pd
          flash[:notice] = t(".successfully_declared") if current_user.save
        else
          flash[:warning] = t(".did_not_confirm")
        end
      end

      redirect_to account_path
    end
  end
end
