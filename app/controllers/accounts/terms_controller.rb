# frozen_string_literal: true

module Accounts
  class TermsController < ApplicationController
    include SessionMethods

    layout :site_layout

    before_action -> { authorize_web(:skip_terms => true) }
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :class => :account_terms

    def show
      @legale = params[:legale] || OSM.ip_to_country(request.remote_ip) || Settings.default_legale
      @text = OSM.legal_text_for_country(@legale)
      @text_legale = @legale
      @text_legale = "GB" unless @legale == "FR" || @legale == "IT"

      if request.xhr?
        render :partial => "terms"
      else
        @title = t ".title"
      end
    end

    def update
      if params[:decline] || !(params[:read_tou] && params[:read_ct])
        current_user.terms_seen = true

        flash[:notice] = { :partial => "accounts/terms/terms_declined_flash" } if current_user.save
      else
        current_user.tou_agreed = Time.now.utc
        current_user.terms_agreed = Time.now.utc
        current_user.terms_seen = true

        flash[:notice] = t ".terms accepted" if current_user.save
      end

      referer = safe_referer(params[:referer]) if params[:referer]

      redirect_to referer || account_path
    end
  end
end
