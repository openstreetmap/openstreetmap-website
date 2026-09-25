# frozen_string_literal: true

module Accounts
  class DeletionsController < ApplicationController
    layout :site_layout

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => false

    def show; end
  end
end
