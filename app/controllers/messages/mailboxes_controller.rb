module Messages
  class MailboxesController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => Message

    before_action :check_database_readable
  end
end
