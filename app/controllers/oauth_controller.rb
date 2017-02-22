require "oauth/controllers/provider_controller"

class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController

  layout "site"

  def login_required
    authorize_web
    set_locale
    require_user
  end

  def user_authorizes_token?
    any_auth = false

    @token.client_application.permissions.each do |pref|
      if params[pref]
        @token.write_attribute(pref, true)
        any_auth ||= true
      else
        @token.write_attribute(pref, false)
      end
    end

    any_auth
  end

  def revoke
    if params[:token]
      tokens = current_user.oauth_tokens.where(:token => params[:token])
    elsif params[:application]
      tokens = current_user.oauth_tokens.where(:client_application => params[:application])
    end

    if tokens.nil?
      render :text => "", :status => :bad_request
    elsif tokens.empty?
      render :text => "", :status => :not_found
    else
      tokens.each(&:invalidate!)

      flash[:notice] = t("oauth.revoke.flash", :application => tokens.first.client_application.name)

      redirect_to oauth_clients_url(:display_name => current_user.display_name)
    end
  end

  protected

  def oauth1_authorize
    if @token.invalidated?
      @message = t "oauth.oauthorize_failure.invalid"
      render :action => "authorize_failure"
    elsif request.post?
      if user_authorizes_token?
        @token.authorize!(current_user)
        callback_url = if @token.oauth10?
                         params[:oauth_callback] || @token.client_application.callback_url
                       else
                         @token.oob? ? @token.client_application.callback_url : @token.callback_url
                       end
        @redirect_url = URI.parse(callback_url) unless callback_url.blank?

        if @redirect_url.to_s.blank?
          render :action => "authorize_success"
        else
          @redirect_url.query = if @redirect_url.query.blank?
                                  "oauth_token=#{@token.token}"
                                else
                                  @redirect_url.query +
                                    "&oauth_token=#{@token.token}"
                                end

          unless @token.oauth10?
            @redirect_url.query += "&oauth_verifier=#{@token.verifier}"
          end

          redirect_to @redirect_url.to_s
        end
      else
        @token.invalidate!
        @message = t("oauth.oauthorize_failure.denied", :app_name => @token.client_application.name)
        render :action => "authorize_failure"
      end
    end
  end
end
