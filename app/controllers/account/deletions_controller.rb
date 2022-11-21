module Account
  class DeletionsController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => false

    def show; end
  end
end
