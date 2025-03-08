module Accounts
  class TermsController < ApplicationController
    include SessionMethods

    layout "site"

    before_action -> { authorize_web(:skip_terms => true) }
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :class => :account_terms

    def show
      @legale = params[:legale] || OSM.ip_to_country(request.remote_ip) || Settings.default_legale
      @text = OSM.legal_text_for_country(@legale)

      if request.xhr?
        render :partial => "terms"
      else
        @title = t ".title"

        if current_user.terms_agreed?
          # Already agreed to terms, so just show settings
          redirect_to account_path
        end
      end
    end

    def update
      if params[:decline] || !(params[:read_tou] && params[:read_ct])
        current_user.terms_seen = true

        flash[:notice] = { :partial => "accounts/terms/terms_declined_flash" } if current_user.save
      else
        unless current_user.terms_agreed?
          current_user.tou_agreed = Time.now.utc
          current_user.terms_agreed = Time.now.utc
          current_user.terms_seen = true

          flash[:notice] = t ".terms accepted" if current_user.save
        end
      end

      referer = safe_referer(params[:referer]) if params[:referer]

      redirect_to referer || account_path
    end
  end
end
