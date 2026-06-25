module Accounts
  class BlocksController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => :account_block

    def index
      unseen_block = current_user.blocks.where(:deactivates_at => nil).order(:id).take
      if unseen_block
        redirect_to unseen_block
      else
        active_block = current_user.blocks.active.order(:id).take
        redirect_to active_block if active_block
      end
    end
  end
end
