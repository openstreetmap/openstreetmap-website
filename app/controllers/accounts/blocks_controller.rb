module Accounts
  class BlocksController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => :account_block

    def index; end
  end
end
