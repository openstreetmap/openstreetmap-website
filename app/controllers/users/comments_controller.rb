module Users
  class CommentsController < ApplicationController
    include UserMethods
    include PaginationMethods

    layout "site"

    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource

    before_action :lookup_user

    allow_thirdparty_images
  end
end
