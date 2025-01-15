module Accounts
  class TermsController < ApplicationController
    include SessionMethods

    layout "site"

    before_action :disable_terms_redirect
    before_action :authorize_web
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

        if current_user&.terms_agreed?
          # Already agreed to terms, so just show settings
          redirect_to edit_account_path
        elsif current_user.nil?
          redirect_to login_path(:referer => request.fullpath)
        end
      end
    end

    def update
      @title = t "users.new.title"

      if params[:decline] || !(params[:read_tou] && params[:read_ct])
        if current_user
          current_user.terms_seen = true

          flash[:notice] = { :partial => "accounts/terms/terms_declined_flash" } if current_user.save

          referer = safe_referer(params[:referer]) if params[:referer]

          redirect_to referer || edit_account_path
        elsif params[:decline]
          redirect_to t("accounts.terms.show.declined"), :allow_other_host => true
        else
          redirect_to account_terms_path
        end
      elsif current_user
        unless current_user.terms_agreed?
          current_user.consider_pd = params[:user][:consider_pd]
          current_user.tou_agreed = Time.now.utc
          current_user.terms_agreed = Time.now.utc
          current_user.terms_seen = true

          flash[:notice] = t "users.new.terms accepted" if current_user.save
        end

        referer = safe_referer(params[:referer]) if params[:referer]

        redirect_to referer || edit_account_path
      end
    end
  end
end
