# frozen_string_literal: true

json.url auth_deletion_url(:provider => params[:provider],
                           :confirmation_code => @confirmation_code)
json.confirmation_code @confirmation_code
